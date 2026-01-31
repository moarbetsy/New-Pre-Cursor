# Comprehensive Analysis: moarbetsy GitHub Repositories

**Analysis Date:** January 29, 2026
**Repositories Analyzed:**
1. [Precursor](https://github.com/moarbetsy/Precursor.git)
2. [setup-cursor](https://github.com/moarbetsy/setup-cursor.git)
3. [governance_system_template](https://github.com/moarbetsy/governance_system_template.git)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Repository 1: Precursor](#2-repository-1-precursor)
3. [Repository 2: setup-cursor](#3-repository-2-setup-cursor)
4. [Repository 3: governance_system_template](#4-repository-3-governance_system_template)
5. [Technical Comparison](#5-technical-comparison)
6. [Integration Assessment](#6-integration-assessment)
7. [Usage Guides](#7-usage-guides)
8. [Making the tools more universal](#8-making-the-tools-more-universal)
9. [Monetization options](#9-monetization-options)

---

## 1. Executive Summary

| Repository | Primary Purpose | Stack | Maturity |
|------------|-----------------|-------|----------|
| **Precursor** | Config-driven project doctor + Cursor scaffolder; idempotent bootstrap, rules, CI, MCP | TypeScript (Bun), PowerShell 7 | High – full docs, tests, schema |
| **setup-cursor** | Windows dev environment installer; winget-like setup for Cursor + UV/Bun/Git + project templates | PowerShell 7, Python (minimal) | Medium – script-heavy, embeds Precursor |
| **governance_system_template** | Governance + template for polyglot repos; pinned toolchain, one rewriter per extension, `just` CLI | TypeScript, Python, Rust, justfile | Medium – constitution, CI, minimal app code |

**Key Finding:** The three repos are **complementary, not redundant**. Precursor focuses on *project-level* Cursor rules, CI, and tooling config; setup-cursor on *machine-level* Windows + Cursor setup and project creation; governance_system_template on *policy and contract* (lockfiles, formatters, one rewriter per extension). Merging them into one repo would be possible but would mix distinct concerns (machine setup vs. project doctor vs. governance contract). **Recommendation:** Keep as separate repos; use together in a workflow: setup-cursor for environment, then clone governance_system_template or use Precursor for project bootstrap and rules.

---

## 2. Repository 1: Precursor

### 2.1 Deep Code Analysis

#### Project Structure

```
precursor/
├── precursor.ps1           # PowerShell entry (finds Bun, runs src/cli.ts)
├── precursor.json         # Default config
├── precursor.schema.json   # JSON Schema for config validation
├── package.json           # Bun/Node; deps: @modelcontextprotocol/sdk, ajv, jsonc-parser, yaml
├── tsconfig.json, biome.json
├── src/
│   ├── index.ts           # setup(), scan(), rollback(), reset(); orchestration
│   ├── cli.ts             # Arg parsing: setup, scan, rollback, reset + strict/offline/json/noColor
│   ├── config.ts         # Load/validate precursor.json | .jsonc | .yaml
│   ├── detector.ts       # Stack detection (pyproject.toml, package.json, Cargo.toml, etc.)
│   ├── toolchain.ts      # Tool resolution (PATH → package manager → portable cache)
│   ├── doctor.ts         # Health checks, doctor_fix (scaffold ruff/biome/clang-format)
│   ├── scaffold.ts       # Generate .cursor/rules/*.mdc, .vscode/settings.json, mcp.json, etc.
│   ├── merge.ts          # Deep merge (no clobber); used for JSON/JSONC/YAML
│   ├── state.ts          # Hash-based state (.precursor/state.json) for idempotency
│   ├── backup.ts         # Timestamped backups, restore
│   ├── ci.ts             # GitHub Actions workflow generation per stack
│   ├── secrets.ts        # Secret scanning (high-entropy, patterns)
│   ├── report.ts         # Collect REPORT.md entries, dedupe, merge to .precursor/reports
│   ├── verification.ts  # Post-scaffold verify (tests, lint, typecheck)
│   ├── hooks.ts          # Post-scaffold hooks (e.g. format after generate)
│   ├── knowledge.ts     # PRECURSOR.md knowledge base
│   ├── commands.ts      # Slash commands (shell + interactive steps)
│   ├── system.ts
│   └── *.test.ts        # Tests for detector, merge, state
├── .precursor/mcp/server.ts   # MCP server: doctor_diagnose, doctor_fix, scaffold_rule, collect_report, etc.
└── .cursor/rules/       # Generated rule files (diagnostics, python-3-14, web, windows, issue-reporting)
```

#### Key Implementation Details

- **Entry:** `precursor.ps1` checks for Bun, installs deps if needed, then runs `bun run src/cli.ts` with parsed args.
- **Config:** Loaded via `config.ts`; supports JSON, JSONC, YAML; validated with AJV against `precursor.schema.json`.
- **Idempotency:** `state.ts` keeps file hashes; scaffold/merge only write when content would change.
- **Stacks:** Detector looks for `pyproject.toml`, `package.json`, `Cargo.toml`, `CMakeLists.txt`, `Dockerfile`, etc., and returns list of stack names (e.g. `python`, `web`, `rust`).
- **Scaffolding:** Writes/merges `.cursor/rules/*.mdc`, `.vscode/settings.json`, `.cursor/mcp.json`, `.github/workflows/*.yml`; uses `merge.ts` so user edits are preserved.
- **MCP server:** Exposes tools for Cursor (e.g. run doctor, apply fix, scaffold rule, collect report). Uses `@modelcontextprotocol/sdk`, stdio transport.

#### Dependencies (package.json)

- **Runtime:** Bun (TypeScript executed directly).
- **Key packages:** `@modelcontextprotocol/sdk`, `ajv`, `jsonc-parser`, `yaml`. Dev: `@types/bun`, `@types/node`, `typescript`.

#### Configuration Files

- **precursor.json:** Example config for python (uv, ruff, pyright), web (bun, biome, tsc), rust, cpp, ci, mcp, secrets, backup.
- **precursor.schema.json:** Full schema for all sections (tools, python, web, rust, cpp, docker, workspace, ci, mcp, secrets, backup, strict, report, verification, hooks, knowledge, commands).

### 2.2 Purpose & Functionality

- **What it does:** Idempotent “project doctor” and scaffolder for Cursor: detects stacks, ensures tools (or reports missing), generates Cursor rules, VS Code settings, MCP config, GitHub Actions workflows, runs verification and post-scaffold hooks, optional secret scan and report collection.
- **Target audience:** Teams using Cursor who want consistent project setup, Cursor rules, and CI; polyglot projects (Python, Web/TS, Rust, C++, Docker).
- **Core features:** Idempotent setup, config-driven behavior, deep merge (no clobber), state/hash cache, backups/rollback, MCP integration, verification loops, hooks, knowledge base (PRECURSOR.md), slash commands.
- **Innovations:** Single config file driving rules + CI + MCP; “one rewriter per stack” implied by generated rules; report collection for training/learning; verification and hooks aligned with quality feedback.

### 2.3 Maturity & Maintenance

- **Maturity:** High. Version 1.0.0, DOCUMENTATION.md, schema, tests, clear CLI and API.
- **Maintenance:** Active (docs dated January 2026). No explicit versioning policy for dependencies beyond “latest” for some devDeps.

---

## 3. Repository 2: setup-cursor

### 3.1 Deep Code Analysis

#### Project Structure

```
setup-cursor/
├── run.ps1                    # Main orchestrator (~1300+ lines): Setup, Doctor, NewProject, Clean, etc.
├── setup-cursor-profile.ps1    # Defines setup-cursor function + alias sc; forwards to run.ps1
├── setup-cursor.psm1          # Module: dots profile script to load setup-cursor
├── setup-cursor.psd1          # Module manifest
├── install-global.ps1         # Install globally (PowerShellProfile, BatchFile, or Path)
├── install-from-anywhere.ps1  # One-liner: irm ... | iex
├── setup-cursor.cmd            # Batch wrapper for pwsh
├── cursorkit.ps1              # Helper/utilities
├── create-release.ps1, test-setup.ps1
├── main.py                    # Minimal Python entry (hello-world style)
├── pyproject.toml, requirements.txt, uv.lock
├── package.json               # Minimal (e.g. for Bun if used)
├── .vscode/settings.json, extensions.json
├── precursor/                 # Embedded copy of Precursor repo (full clone)
│   ├── precursor.ps1, src/, .cursor/, .github/, etc.
│   └── (same layout as Precursor repo)
└── .cursor/rules/, INCIDENTS.md, REPORT.md
```

#### Key Implementation Details

- **Entry:** User runs `setup-cursor -Setup` (or `sc -Setup`). Profile script resolves script dir, finds `run.ps1`, and invokes it with the same parameters.
- **run.ps1:** Large PowerShell script that:
  - **-Setup:** Installs tools (UV, Bun, Git via winget), creates/updates venv, installs Python/JS deps, applies Cursor/VSCode settings, applies fixes from REPORT.md, runs “Bootstrap” (creates missing files), runs validation.
  - **-NewProject:** Creates a new project folder with `src/`, `run.ps1`, `main.py`, `pyproject.toml`, `package.json`, `.vscode`, `.cursor`, `REPORT.md`, etc., and optional file exclusions so IDE shows mainly `src/`.
  - **-Doctor:** Runs diagnostics (tool versions, venv, deps, settings).
  - **-Bootstrap:** Creates essential files (e.g. run.ps1, main.py, pyproject.toml, REPORT.md) if missing.
  - **-Clean:** Removes venv, node_modules, etc.
- **Bootstrap:** Implemented inside `run.ps1` (function `Invoke-Bootstrap`). It does **not** call the embedded Precursor by default; it creates a fixed set of files. The embedded `precursor/` is available for users who want to run Precursor separately (e.g. `.\precursor\precursor.ps1 -Setup`).
- **Install methods:** `install-global.ps1` can add setup-cursor to PowerShell profile, or install a .cmd in a PATH directory; `install-from-anywhere.ps1` is for one-line remote install.

#### Dependencies

- **PowerShell 7+** required.
- **External tools:** UV, Bun, Git (installed via winget or similar during -Setup).
- **Python:** Used for a trivial `main.py`; project uses `pyproject.toml` and `uv`.

### 3.2 Purpose & Functionality

- **What it does:** Provides a single global command (`setup-cursor`) to set up a Windows development environment for Cursor: install UV, Bun, Git, configure Cursor/VSCode (terminal, IntelliSense, file exclusions), create/update Python venv and JS deps, create new projects from a template, run doctor and cleanup.
- **Target audience:** Windows users (especially with Cursor) who want a “winget-like” one-command environment setup and project scaffolding.
- **Core features:** Global CLI, tool installation, IDE settings, “clean explorer” (only `src/` visible by default), REPORT.md issue tracking, new project creation, doctor and clean.
- **Philosophy:** “Everything I touch goes in `src/`; everything else is the machine room.”

### 3.3 Maturity & Maintenance

- **Maturity:** Medium. README is detailed; implementation is mostly one large PowerShell script; some structure (REPORT.md, INCIDENTS, .cursor rules). No formal test suite for run.ps1.
- **Maintenance:** Appears active. Contains embedded Precursor snapshot; versioning of that snapshot not clearly documented.

---

## 4. Repository 3: governance_system_template

### 4.1 Deep Code Analysis

#### Project Structure

```
governance_system_template/
├── justfile              # Canonical commands: fmt, lint, type, test, ci; delegates to scripts
├── CONSTITUTION.md       # Contract: runtimes, toolchain, ownership, lockfile law, merge gates
├── docs/
│   ├── WORKFLOW.md       # Install, daily commands, CI contract, Node break-glass
│   ├── OWNERSHIP.md      # One rewriter per extension (Ruff, Biome, dprint, cargo fmt)
│   ├── WINDOWS.md
│   ├── GOVERNANCE_GRAPH.md
│   └── ...
├── scripts/
│   ├── run-if-path.ts    # Run command only if path exists (e.g. pyproject.toml)
│   ├── js-lockfile-law.ts
│   ├── py-lockfile-law.ts
│   ├── pytest-ci.ts
│   ├── doctor.sh, doctor.ps1
│   └── ...
├── src/index.ts          # Minimal (e.g. export hello)
├── rust/lib.rs           # Minimal Rust lib
├── package.json          # Bun 1.3.7; biome, typescript, vitest, dprint
├── pyproject.toml        # uv; ruff, pyright, pytest; requires-python >=3.11,<3.15
├── Cargo.toml, rust-toolchain.toml
├── biome.json, dprint.json
├── .bun-version, .nvmrc, .python-version
├── .github/workflows/ci.yml   # Runs just ci (lockfile laws, fmt-check, lint-check, type, test)
├── PSScriptAnalyzerSettings.psd1
├── fix-heading.js, fix-heading2.js
└── SECURITY.md, CONTRIBUTING.md
```

#### Key Implementation Details

- **justfile:** Default target is `ci`. Defines:
  - **js-lockfile-law** / **py-lockfile-law:** Enforce single JS lockfile (bun.lock) and uv.lock.
  - **py-fmt / py-fmt-check, py-lint / py-lint-check, py-type, py-test:** Via `run-if-path.ts pyproject.toml -- ...`.
  - **web-fmt / web-fmt-check, web-lint / web-lint-check, web-type, web-test:** Via `run-if-path.ts package.json -- ...`.
  - **docs-fmt / docs-fmt-check:** dprint.
  - **rs-fmt, rs-fmt-check, rs-lint, rs-test:** Via `run-if-path.ts Cargo.toml -- cargo ...`.
  - **ps-lint:** PSScriptAnalyzer.
  - **fmt / fmt-check / lint / lint-check / type / test:** Composed from above.
  - **ci:** js-lockfile-law, py-lockfile-law, fmt-check, lint-check, type, test (no writes).
- **CI (ci.yml):** Ubuntu 24.04; Bun from .bun-version; Python 3.14.2; uv pinned; Rust stable 1.93.0; installs `just`; runs `just ci`.
- **Constitution:** Pins runtimes (Python, Bun, Node break-glass, Rust, PowerShell); one rewriter per extension; lockfile law (only bun.lock, uv.lock); merge gates (fmt-check, lint-check, type, test, build if needed); canonical surface is `just`.

### 4.2 Purpose & Functionality

- **What it does:** Defines a governance contract and template for polyglot repos: pinned runtimes and tools, “one rewriter per extension,” single lockfile per ecosystem, and a single command surface (`just`) for both humans and CI.
- **Target audience:** Teams (3+ devs), polyglot codebases (Python + JS/TS + Rust, optional PowerShell), orgs standardizing CI/lint/format across repos, Windows devs (WSL2 or PowerShell).
- **Core features:** Constitution, justfile-driven workflow, run-if-path (optional stacks), lockfile laws, Node as break-glass runtime only, doctor scripts.
- **Innovations:** Explicit “Boss Rule” (one rewriter per extension); Bun-first with Node fallback; Python “run newest, type-check minimum” policy.

### 4.3 Maturity & Maintenance

- **Maturity:** Medium. Strong documentation (CONSTITUTION, docs/), working CI, minimal application code (template only).
- **Maintenance:** Appears active. Pinned versions in CI and configs.

---

## 5. Technical Comparison

| Dimension | Precursor | setup-cursor | governance_system_template |
|-----------|-----------|--------------|----------------------------|
| **Primary language** | TypeScript (Bun) | PowerShell 7 | TypeScript, Python, Rust, just |
| **Entry point** | precursor.ps1 → Bun → src/cli.ts | run.ps1 (or profile → run.ps1) | just (justfile) |
| **Config** | precursor.json (schema-validated) | .env, run.ps1 params | CONSTITUTION.md, justfile, pyproject/biome/Cargo |
| **Orchestration** | TS (setup/scan/rollback/reset) | Single large PS1 script | justfile recipes |
| **Stacks** | Python, web, Rust, C++, Docker (detected) | Python + JS (UV + Bun) | Python, web, Rust, PowerShell (optional) |
| **Toolchain** | Configurable (e.g. uv, ruff, bun, biome) | UV, Bun, Git (fixed) | Pinned: uv, ruff, pyright, bun, biome, tsc, vitest, dprint, cargo |
| **CI** | Generates GitHub Actions per stack | N/A (user’s CI) | Single workflow: just ci |
| **Cursor integration** | .cursor/rules, .cursor/mcp.json, MCP server | .vscode/.cursor settings, file exclusions | None (no Cursor-specific generation) |
| **Lockfile policy** | Not enforced | N/A | Enforced (bun.lock only; uv.lock required) |
| **Format/lint** | Generated rules + hooks | IDE settings | One rewriter per extension (Ruff, Biome, dprint, cargo fmt) |
| **Scope** | Project-level (per-repo bootstrap) | Machine + project template | Repo-level contract + template |

### Overlapping Functionality

- **Python + JS tooling:** All three assume or use UV/Bun (and Ruff/Biome for lint/format where applicable). Precursor and governance_system_template both encode “preferred” toolchains; setup-cursor installs UV/Bun and uses them in projects.
- **Environment consistency:** Precursor and governance_system_template both aim for reproducible, consistent tooling; Precursor via config and generation, governance via constitution and justfile.
- **Doctor/diagnostics:** Precursor has `scan`/doctor; setup-cursor has `-Doctor`; governance has `just doctor` / `just doctor-windows`.

### Differences in Approach

- **Precursor:** Config-driven, idempotent, Cursor-centric (rules, MCP, report collection). Doesn’t install OS-level tools; assumes Bun available.
- **setup-cursor:** Installer and project creator; Windows-focused; “one command” experience; embeds Precursor but doesn’t run it in the main flow.
- **governance_system_template:** Policy and template only; no Cursor-specific generation; `just` as single CLI; strict lockfile and rewriter ownership.

---

## 6. Integration Assessment

### 6.1 Could These Be Merged?

- **Technically:** Yes. They could live in one monorepo (e.g. `precursor/`, `setup-cursor/`, `governance/` or `templates/governance/`).
- **Conceptually:** They solve different problems:
  - **Precursor:** Project doctor and Cursor scaffolding (rules, CI, MCP).
  - **setup-cursor:** Machine and project setup on Windows.
  - **governance_system_template:** Repo governance contract and starter template.

### 6.2 Benefits of Merging

- Single place for “Cursor + modern stack” tooling.
- Shared versioning and releases (if desired).
- Cross-repo fixes and docs in one clone.

### 6.3 Challenges of Merging

- Different audiences and triggers: “install my machine” vs “bootstrap this repo” vs “start a governed repo.”
- setup-cursor is PowerShell-heavy and Windows-oriented; Precursor is Bun/TS; governance is just + multi-language. CI and packaging would need to support all.
- governance_system_template is meant to be cloned as a new project root; merging could confuse “template clone” vs “using Precursor/setup-cursor.”

### 6.4 Recommendation

- **Keep repositories separate.** Use them together in a clear workflow:
  1. **Machine setup (Windows):** `setup-cursor -Setup` (and optionally global install).
  2. **New governed project:** Clone `governance_system_template` and rename; or use Precursor in an existing repo.
  3. **Existing project / Cursor rules + CI:** Add Precursor (`precursor.json`, then `.\precursor.ps1 -Setup`), possibly after running setup-cursor for tools.

If you still want a single repo, a possible layout:

- `machine-setup/` → current setup-cursor (run.ps1, install-*, profile).
- `project-doctor/` → current Precursor (precursor.ps1, src/, .precursor).
- `templates/governance/` → current governance_system_template (justfile, CONSTITUTION, scripts, etc.).

With a top-level README explaining: “Machine setup → machine-setup. Project doctor and Cursor → project-doctor. New governed repo → clone templates/governance.”

---

## 7. Usage Guides

### 7.1 Precursor

#### Prerequisites

- PowerShell 7+
- Bun ([bun.sh](https://bun.sh))
- Git

#### Setup / Installation

```powershell
git clone https://github.com/moarbetsy/Precursor.git
cd Precursor
bun install
```

#### Basic usage

```powershell
# Read-only health check
.\precursor.ps1 -Scan

# Full bootstrap (idempotent)
.\precursor.ps1 -Setup

# CI: strict, JSON
.\precursor.ps1 -Setup -Strict --json
.\precursor.ps1 -Scan --json --no-color > report.json

# Offline (no downloads)
.\precursor.ps1 -Setup -Offline

# Rollback / reset state
.\precursor.ps1 -Rollback
.\precursor.ps1 -ResetState
```

#### Optional config

Create `precursor.json` in project root (or use repo default). Minimum for MCP:

```json
{
  "$schema": "./precursor.schema.json",
  "mcp": { "enabled": true },
  "ci": { "enabled": true },
  "secrets": { "enabled": true },
  "backup": { "enabled": true, "maxBackups": 10 }
}
```

#### Practical example

In a repo that already has `pyproject.toml` and `package.json`:

```powershell
cd my-project
# Copy or symlink Precursor into repo, or run from Precursor clone with project path
.\precursor.ps1 -Setup
# Then: open Cursor; .cursor/rules and .cursor/mcp.json are ready; run -Scan to verify.
```

---

### 7.2 setup-cursor

#### Prerequisites

- Windows
- PowerShell 7+
- Internet (for first-time install)

#### One-line install (global)

```powershell
irm https://raw.githubusercontent.com/moarbetsy/setup-cursor/main/install-from-anywhere.ps1 | iex
```

#### Manual install

```powershell
git clone https://github.com/moarbetsy/setup-cursor.git
cd setup-cursor
.\install-global.ps1 -Method PowerShellProfile
# Restart PowerShell/Cursor
```

#### Basic usage

```powershell
# Full environment setup (tools, venv, IDE settings, bootstrap)
setup-cursor -Setup
# or
sc -Setup

# Create new project
setup-cursor -NewProject "my-app"
cd my-app

# Diagnostics
setup-cursor -Doctor

# Install/update tools only
setup-cursor -InstallTools

# Clean project
setup-cursor -Clean
```

#### Practical example

```powershell
# From any directory after global install
setup-cursor -Setup
setup-cursor -NewProject "my-web-app"
cd my-web-app
# Run project (dashboard)
setup-cursor
# Choose option 1 (Python) or 2 (JS) to run
```

---

### 7.3 governance_system_template

#### Prerequisites

- Bun (or Node break-glass)
- uv (Python)
- just
- Optional: Rust toolchain, PowerShell 7 (for ps-lint)

#### Setup (recommended: WSL2 + Ubuntu)

```bash
git clone https://github.com/moarbetsy/governance_system_template.git my-project
cd my-project
# Rename repo / update CONSTITUTION if desired

bun install --frozen-lockfile
pipx install "uv==0.9.27"
uv sync --frozen
just ci
```

#### Windows (PowerShell 7)

```powershell
# Install just (e.g. winget)
bun install --frozen-lockfile
# Install uv (e.g. pip or pipx)
uv sync --frozen
just ci
```

#### Daily workflow

```bash
just fmt      # Rewrite (format)
just lint     # Lint with fix where allowed
just type     # Type-check
just test     # Run tests
just ci       # Full check (what CI runs)
```

#### Practical example

```bash
# Clone as new project
git clone https://github.com/moarbetsy/governance_system_template.git acme-backend
cd acme-backend
# Update package name, project name in pyproject.toml / package.json
bun install --frozen-lockfile
uv sync --frozen
just ci
# Then develop using only: just fmt, just lint, just type, just test
```

---

## 8. Making the tools more universal

The tools are currently most effective on **Windows**, with **Cursor**, and with a **UV/Bun/just** stack. To make them usable on more platforms, editors, and toolchains without losing focus, use a **platform layer + optional Cursor/editor layer** and **contracts that can be fulfilled by multiple runtimes**.

### 8.1 setup-cursor: cross-platform machine setup

| Current limitation | Direction for more universal use |
|--------------------|-----------------------------------|
| Windows-only (PowerShell, winget) | Add a **cross-platform entrypoint** that delegates to platform-specific scripts. |
| Cursor-centric naming and defaults | Keep Cursor as default; make **editor and tools optional** via flags or config. |

**Concrete options:**

1. **Multi-platform entrypoint**
   - Add a single entrypoint that works everywhere (e.g. `setup` or `setup-dev`): a small **Node/Bun** or **Python** script that detects OS and invokes the right backend.
   - Backends: existing `run.ps1` for Windows; new **Bash** script for macOS/Linux that uses Homebrew/apt/dnf for UV, Bun, Git and (optionally) Cursor.
   - Same UX: “run this one command to get a dev environment.”

2. **Extract “core” vs “Cursor”**
   - Core: install UV, Bun, Git, create venv, install deps, bootstrap project files.
   - Optional: Cursor/VS Code settings, Cursor-specific profile.
   - Users on other editors get the same environment; Cursor users get the extra layer.

3. **Document “manual” path for non-Windows**
   - One-page “Manual setup (macOS/Linux)” that lists: install UV, Bun, Git (with exact commands per OS), then clone project and run Precursor.
   - setup-cursor stays Windows-optimized; universality comes from Precursor + governance_system_template being platform-agnostic.

### 8.2 Precursor: editor-agnostic core + Cursor layer

| Current limitation | Direction for more universal use |
|--------------------|-----------------------------------|
| Entry is `precursor.ps1` (PowerShell) | Add a **Bun/Node entrypoint** (`precursor` or `bun run src/cli.ts`) so any platform can run it without PowerShell. |
| Outputs are Cursor-focused (.cursor/rules, mcp.json) | Treat **Cursor rules and MCP as one output profile**; add optional profiles for other editors. |

**Concrete options:**

1. **Universal CLI entry**
   - `package.json` scripts: `"precursor": "bun run src/cli.ts"` (or `node` if Bun is optional).
   - Document: “Run `bun run precursor -- setup` (or `npx precursor setup`) from any OS.”
   - Keep `precursor.ps1` as a **Windows convenience wrapper** that finds Bun and invokes the same CLI.

2. **Editor profiles in config**
   - `precursor.json`: e.g. `"editors": ["cursor"]` or `["cursor", "vscode"]`.
   - Scaffold only what’s selected: Cursor → `.cursor/`, MCP; VS Code → `.vscode/`; both if requested.
   - Other editors: only CI, doctor, and tool config (no editor-specific dirs). That keeps one codebase, multiple audiences.

3. **MCP and rules as optional**
   - Config: `mcp: { "enabled": false }`, `rules: { "enabled": false }`.
   - When disabled, Precursor still does: stack detection, doctor, CI workflow generation, backup/rollback.
   - “Universal” = “project doctor + CI + optional Cursor/VS Code.”

### 8.3 governance_system_template: multiple runtimes, same contract

| Current limitation | Direction for more universal use |
|--------------------|-----------------------------------|
| Tied to UV + Bun + just | Define the **contract** (lockfiles, one rewriter per extension, single CLI) and allow **alternative runtimes** that satisfy it. |
| Some scripts are Bash/PowerShell (doctor) | Keep both; add a small **just** or **Bun** driver that picks the right script by OS. |

**Concrete options:**

1. **Contract over implementation**
   - CONSTITUTION.md states: “Repos must have locked deps, one formatter per extension, and a single entrypoint (e.g. `just ci`).”
   - Provide **two** reference implementations: current (UV + Bun + just) and an **alternative** (e.g. npm/pnpm + pip/venv + make or just). Same `just ci` semantics (fmt-check, lint, type, test), different tools.
   - Users who can’t use UV/Bun can still adopt the contract with their stack.

2. **Optional stacks in the template**
   - Template layout: `justfile` + `CONSTITUTION.md` plus **optional** `package.json`/`pyproject.toml`/`Cargo.toml`.
   - “Minimal” clone: just + CONSTITUTION + one language (e.g. only Python).
   - “Full” clone: current polyglot. Reduces friction for teams that only need one runtime.

3. **Platform-agnostic doctor**
   - Single entry: `just doctor` (or `./scripts/doctor`) that runs `doctor.sh` on Unix and `doctor.ps1` on Windows (e.g. from justfile with `os()`).
   - Same contract: “Doctor checks tool versions, lockfile, and lint/format.” Implementation can differ by OS.

### 8.4 Ecosystem: one story for “any platform, any editor”

- **Machine:** “Run one setup command” — on Windows that’s setup-cursor; on macOS/Linux it’s either a Bash/Homebrew script (if added) or the documented manual steps plus Precursor.
- **Project:** “One project doctor” — Precursor, runnable via Bun/Node from any OS; optional Cursor/VS Code output.
- **Governance:** “One contract” — lockfiles, one rewriter per extension, single CLI; governance_system_template as reference with optional alternative runtimes.

**Priority order if you can’t do everything:**
1. **Precursor:** Add Bun/Node entrypoint and editor profiles (biggest gain for non-Windows and non-Cursor).
2. **governance_system_template:** Document contract and add one alternative runtime (e.g. npm + make) so more teams can adopt it.
3. **setup-cursor:** Add a Bash backend or a “manual setup” doc so macOS/Linux users have a clear path to the same stack.

---

## 9. Monetization options

The repos are open-source and developer-focused. Monetization works best when the **core stays free** and revenue comes from **services, hosted/team features, or ecosystem**—so adoption and trust stay high while creating clear paid value.

### 9.1 By product

| Product | Free (keep) | Monetize via |
|--------|-------------|----------------|
| **setup-cursor** | Scripts, profile, bootstrap, one-command setup | **Support / onboarding:** Paid “we set up your team’s machines” (remote or on-site). **Enterprise pack:** Pre-configured image or GPO/Intune bundle for org rollout; optional branded project template. |
| **Precursor** | CLI, doctor, scaffold, rules/MCP/CI generation, config schema | **Open-core:** Free for individuals/small teams; **Pro/Team:** Shared rule packs, team config sync, audit log. **Hosted doctor:** SaaS dashboard (repo health, drift, compliance) that runs Precursor under the hood. **Marketplace:** Sell curated rule packs or vertical templates (e.g. “Precursor for Django”, “Precursor for React + API”). |
| **governance_system_template** | Justfile, CONSTITUTION, scripts, template clone | **Consulting / adoption:** “Governance in a day”—workshop or engagement to adopt the contract and customize CONSTITUTION. **Certified template:** Paid vertical (e.g. “Governance template for fintech”) with extra compliance docs and CI. **Training:** Certification or course on “governed polyglot repos” using this stack. |

### 9.2 Cross-cutting models

1. **Services (highest fit, lowest scale)**
   - **Implementation:** Help companies adopt setup-cursor + Precursor + governance_system_template (machine setup, repo bootstrap, CONSTITUTION tuning). Fixed or day-rate.
   - **Support:** Retainer for “we fix your config, upgrade your rules, debug doctor/CI.”
   - **Training:** Workshops or video course: “Cursor + governed repos from zero.”

2. **Freemium / open-core (scale, recurring)**
   - **Precursor Pro/Team:** Free tier = single user, local only. Paid = team config sync, shared rule packs, optional hosted doctor/audit.
   - **Hosted “Project Doctor”:** Run Precursor in the cloud per repo; dashboard shows health, drift, secrets, CI status. Free for 1 repo, paid for more or for teams.
   - **setup-cursor:** Free as-is. Paid “Enterprise setup” = pre-built image or managed rollout (see above).

3. **Ecosystem / marketplace (optional)**
   - **Rule packs / MCP packs:** Curated `.cursor/rules` or MCP configs by stack or vertical (e.g. “Python API”, “React + TypeScript”)—one-time or subscription.
   - **Templates:** governance_system_template stays free; sell “Governance template + compliance add-on” or “Precursor + industry rules” bundles.
   - **Affiliate / partnership:** If Cursor or others have referral programs, link from docs; or partner with consultancies that resell your services.

4. **Enterprise / compliance (high ACV, slow)**
   - **Precursor Enterprise:** SSO, audit log of who ran doctor/scaffold when, export for compliance, “locked” rule sets approved by security.
   - **Governance certification:** “This repo conforms to [your] governance contract” badge or report; sell to orgs that need to prove policy (e.g. SOC2, internal standards).
   - **setup-cursor for IT:** Volume license or support for IT rolling out Cursor + UV/Bun to hundreds of devs.

### 9.3 Practical order

- **Fastest to revenue:** Services (implementation, support, training)—no product change, sell your time and expertise.
- **Recurring and scalable:** Open-core Precursor (team/hosted) or hosted Project Doctor; requires building a small paid layer and billing.
- **Later:** Marketplace (rule packs, templates), enterprise features (SSO, audit), and setup-cursor enterprise/IT—once you have enough users and demand.

**Principle:** Keep the three repos free and usable as they are. Monetize **around** them (services, hosted layer, premium templates, enterprise) so the community keeps adopting and contributing while you have clear paid offerings.

---

## Summary Table: When to Use What

| Goal | Use |
|------|-----|
| Set up Windows + Cursor + UV/Bun/Git and get a project template | **setup-cursor** |
| Add Cursor rules, MCP, CI workflows, and project doctor to an existing repo | **Precursor** |
| Start a new repo with strict governance (lockfiles, one rewriter per extension, just) | **governance_system_template** |
| Combine: install environment, then add Cursor/CI to a governed repo | **setup-cursor** then **Precursor** (and optionally clone **governance_system_template** as base) |

### Expanded explanations

**1. Set up Windows + Cursor + UV/Bun/Git and get a project template → use setup-cursor**

Use this when you are on a **new or freshly installed Windows machine** and want a single path to a working Cursor dev environment and a ready-to-use project. setup-cursor is a **machine-level** installer: it installs (e.g. via winget) UV, Bun, Git, and Cursor-related tooling; configures your PowerShell profile and aliases (`sc`); creates or updates a venv and installs dependencies; and can bootstrap a new project folder with `src/`, `run.ps1`, `main.py`, `pyproject.toml`, `.vscode`, `.cursor`, and `REPORT.md`. You get a runnable project template and a consistent way to run it (`setup-cursor` or `sc`). It does **not** by default add Cursor rules, MCP, or CI—those come from Precursor, which setup-cursor can invoke separately via its embedded Precursor copy.

**2. Add Cursor rules, MCP, CI workflows, and project doctor to an existing repo → use Precursor**

Use this when you **already have a repo** (with `pyproject.toml`, `package.json`, `Cargo.toml`, etc.) and want to add **project-level** Cursor/IDE/CI scaffolding without changing your app code. Precursor is a **project doctor and scaffolder**: it detects stacks (Python, Web/TS, Rust, C++, Docker), validates toolchains, and idempotently generates or merges `.cursor/rules/*.mdc`, `.vscode/settings.json`, `.cursor/mcp.json`, and `.github/workflows/*.yml`. It also provides health checks (doctor), optional secret scanning, report collection, and an MCP server so Cursor can run doctor/scaffold/rollback from inside the editor. Config is driven by `precursor.json` (or .jsonc/.yaml); it uses deep merge and state hashes so your existing edits are preserved.

**3. Start a new repo with strict governance (lockfiles, one rewriter per extension, just) → use governance_system_template**

Use this when you want to **begin a new repository** with **strict policy from day one**: pinned toolchains, lockfiles (e.g. `uv.lock`, `bun.lockfile`), one formatter/rewriter per file type (e.g. Ruff for Python, Biome for JS/TS), and a single CLI surface via **just** (`just fmt`, `just lint`, `just type`, `just test`, `just ci`). Clone governance_system_template as the base of your new repo, rename it, update `pyproject.toml`/`package.json`/CONSTITUTION as needed, then run `bun install --frozen-lockfile`, `uv sync --frozen`, and `just ci`. You get a polyglot (TypeScript, Python, Rust) skeleton with governance and CI already wired; you can add Cursor rules and MCP later with Precursor if you want.

**4. Combine: install environment, then add Cursor/CI to a governed repo → setup-cursor then Precursor (and optionally governance_system_template as base)**

Use this for the **full workflow** on Windows: first get your machine and a project, then add Cursor/CI (and optionally start from a governed base). Step 1: run **setup-cursor** (`setup-cursor -Setup`) to install Windows + Cursor + UV/Bun/Git and optionally create a new project with `-NewProject`. Step 2: either start from an existing repo or, if you want strict governance from the start, clone **governance_system_template** as your project base and then open that folder. Step 3: run **Precursor** in that project (`.\precursor.ps1 -Setup` or, if you used setup-cursor’s embedded copy, `.\precursor\precursor.ps1 -Setup`) to add Cursor rules, MCP config, and CI workflows. Result: a governed, lockfile-pinned repo with Cursor rules, MCP, and CI, all on a machine already set up by setup-cursor.

### Should you always use these tools for every project?

**Short answer:** Use them by default for **new Cursor-based projects** (and for your Windows dev machine). Skip or adapt when platform, editor, or existing policy says otherwise.

**When “use everything” makes sense**

- **New projects** where you use Cursor and want consistent rules, MCP, CI, and (optionally) strict governance from day one. Using setup-cursor (on Windows) + Precursor + optionally governance_system_template gives you one standard stack and fewer one-off decisions.
- **Your main dev machine (Windows).** Running setup-cursor once gives you UV, Bun, Git, and a project template path; then every project can use Precursor and, if you want, a governed base. You get the same workflow across repos.
- **Existing repos** where you’re already standardizing on Cursor. Adding Precursor (rules, MCP, CI, doctor) is usually low-risk and high benefit; it’s idempotent and merges with existing config.

**When “always use everything” doesn’t fit**

- **Not on Windows.** setup-cursor is Windows-focused (PowerShell, winget). On macOS/Linux you’d set up UV/Bun/Git another way and still use **Precursor** and **governance_system_template** in repos.
- **Not using Cursor.** Precursor’s value is Cursor rules, MCP, and Cursor-oriented CI. If you use another editor, Precursor’s rules and MCP are less relevant; you might still use governance_system_template for lockfiles and `just` if you like that contract.
- **Existing org or repo governance.** If the repo already has mandated formatters, CI, or tooling (e.g. company justfile, pre-commit, specific lockfiles), layering these tools on top can conflict. Use Precursor only if it can merge with existing config, or adopt governance_system_template only where you’re allowed to adopt its contract.
- **Tiny or throwaway projects.** For a one-off script or a 5-minute experiment, full setup (setup-cursor + Precursor + governance) may be more overhead than benefit. You can still use them if you want the same habits everywhere.
- **Different toolchain by choice.** If you’ve committed to a different stack (e.g. only npm/pnpm, no UV; or no `just`), governance_system_template’s contract (UV, Bun, just) may not match. Use what fits; Precursor can still add Cursor rules and CI for your stack if the detector supports it.

**Practical recommendation**

- **Default:** For any **new** project where you use Cursor and (on Windows) have or want a standard environment: use **setup-cursor** once on the machine, then for each repo use **Precursor** and, for new repos where you want strict policy, start from **governance_system_template** and then run Precursor. That’s “always use them” in practice for your own Cursor-based workflow.
- **Exceptions:** Don’t force setup-cursor on non-Windows; don’t force Precursor or governance where org policy or existing tooling already defines the contract. For small one-offs, it’s optional.

So: **yes, it’s better to use these tools for (almost) any project** that fits the stack and platform—treat them as the default, and opt out only when platform, editor, or governance constraints say otherwise.

---

*End of analysis.*
