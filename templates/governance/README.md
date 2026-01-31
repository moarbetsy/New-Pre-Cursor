# Governance System Template — Bun-first + Node break-glass

This repository is a **governance system + template** for modern polyglot projects. It is designed to remove common friction points (environment drift, formatting conflicts, ad‑hoc tooling) by enforcing a strict, documented structure.

For the formal contract and deeper detail, read:

- `CONSTITUTION.md`
- `docs/WORKFLOW.md`
- `docs/WINDOWS.md`
- `docs/OWNERSHIP.md`
- `docs/GOVERNANCE_GRAPH.md`

## Overview

**Core goals:**

- **Reproducibility**: Local development must match CI (same runtimes, same tools, same commands).
- **Uniformity**: One blessed way to format, lint, type-check, and test across languages.
- **Stability**: All runtimes and tools are pinned; no floating “latest” and no “it works on my machine”.

## Architecture & philosophy

The system is built on four pillars:

1. **One runtime contract**: Versions for Python, Bun, Node (break-glass only), Rust, and PowerShell are explicitly pinned and must match between dev and CI.
2. **One pinned toolchain**: A single, approved tool is responsible for each concern (formatting, linting, typing, testing) per language.
3. **One rewriter per extension**: Exactly one tool is allowed to rewrite a given file type; other tools may only run in check mode.
4. **One command surface**: All actions (format, lint, type-check, test, CI) are executed via `just ...`, for both humans and CI.

### Tech stack

| Domain                    | Tool                   | Role                                                                        |
| :------------------------ | :--------------------- | :-------------------------------------------------------------------------- |
| **Orchestration**         | `just`                 | Canonical command runner for dev and CI                                     |
| **JavaScript/TypeScript** | `Bun`                  | Default JS runtime and package manager (`bun.lock` is the only JS lockfile) |
| **Python**                | `uv`                   | Python project + environment manager (`uv.lock` is required)                |
| **Python rewrite**        | `Ruff`                 | Format, lint, and import management                                         |
| **Python types**          | `Pyright`              | Static type checking                                                        |
| **Python tests**          | `pytest`               | Test runner                                                                 |
| **Web rewrite**           | `Biome`                | Format + lint for JS/TS/JSON/CSS/HTML                                       |
| **Web types**             | `tsc`                  | TypeScript type checker                                                     |
| **Web tests**             | `Vitest`               | JS/TS test runner                                                           |
| **Docs/data format**      | `dprint`               | Markdown, YAML, TOML formatting                                             |
| **Rust**                  | `cargo fmt` / `clippy` | Format and lint                                                             |
| **PowerShell**            | PSScriptAnalyzer       | Lint PowerShell scripts                                                     |
| **CI**                    | GitHub Actions         | Runs `just ci` in check-only mode                                           |

## Getting started

This repository is meant to be the **root** of a new project (clone and rename), not a nested subfolder.

### Route A (recommended): WSL2 + Ubuntu (best CI parity)

```bash
# 1. Install JS dependencies (Bun-only; produces/uses bun.lock)
bun install --frozen-lockfile

# 2. Install Python tooling (pinned)
pipx install "uv==0.9.27"

# 3. Sync Python environment (uv.lock)
uv sync --frozen

# 4. Run the full check pipeline (what CI runs)
just ci
```

### Route B (fallback): Native Windows + PowerShell 7

- Install PowerShell 7 so `pwsh` is available on `PATH`.
- Install `just` (for example via winget).
- Run the same commands in PowerShell (no Git Bash required).

```powershell
bun install --frozen-lockfile
uv sync --frozen
just ci
```

## Daily development workflow

Do **not** invoke formatters, linters, or test runners directly. Use `just` recipes to guarantee correct arguments, paths, and versions.

| Command     | Purpose                                                                                     |
| :---------- | :------------------------------------------------------------------------------------------ |
| `just fmt`  | **Rewrite locally.** Runs all formatters (Ruff, Biome, dprint, `cargo fmt`) on owned files. |
| `just lint` | **Autofix locally.** Runs linters with fix capabilities where allowed.                      |
| `just type` | **Type-check only.** Runs Pyright and `tsc` without rewriting.                              |
| `just test` | **Run tests.** Executes pytest, Vitest, and any other configured suites.                    |
| `just ci`   | **CI parity check.** Runs the CI pipeline in check-only mode (no writes).                   |

If CI fails, the recovery loop is:

1. Run `just ci` locally.
2. If errors are formatting or linting, run `just fmt` / `just lint` and commit the resulting changes.
3. Re-run `just ci` until clean.

## Governance rules (“the law”)

### Lockfile law

The lockfile policy enforces a single source of truth per ecosystem.

- **JavaScript / TypeScript**
  - **Allowed**: `bun.lock` (owned by Bun).
  - **Forbidden**: `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `npm-shrinkwrap.json`.
  - JS dependencies are installed **only** via Bun.
- **Python**
  - **Required**: `uv.lock` + `pyproject.toml`.
  - Python dependencies are installed **only** via `uv`.

### Extension ownership (one rewriter per extension)

Each file extension has exactly one **rewriter owner**. Others may run only in check mode (no `--fix`, no rewrites).

From `docs/OWNERSHIP.md`:

- **Rewriters**
  - `*.py` → **Ruff**
  - `*.ts, *.tsx, *.js, *.jsx, *.json` → **Biome**
  - `*.css, *.scss, *.sass, *.html` → **Biome**
  - `*.md, *.yaml, *.yml, *.toml` → **dprint**
  - Rust code → **`cargo fmt`**
- **Checkers (no rewriting)**
  - Python types → **Pyright**
  - Rust lint → **Clippy**
  - PowerShell → **PSScriptAnalyzer**

**Boss Rule**: Many tools may _check_; only one tool may _rewrite_ a given extension.

### Python version policy

This repo follows a **“run newest, type-check against minimum”** rule:

- **Runtime**: CI and dev run on a newer pinned Python (currently 3.14.2).
- **Typing / compatibility**: Ruff and Pyright target **Python 3.11** (the minimum supported).

The compatibility range is defined by `requires-python` in `pyproject.toml` (currently `>=3.11,<3.15`).

## Advanced features

### Break-glass Node

Bun is the **default** JS runtime and package manager. Node is permitted only as a **runtime fallback** when Bun exhibits a bug, and it must not introduce npm-managed lockfiles.

Fallback commands (still using dependencies installed by Bun):

- Type-check via Node runtime:

  ```bash
  just web-type-node
  ```

- Run tests via Node runtime:

  ```bash
  just web-test-node
  ```

### Conditional workflows (run-if-path)

The template is designed to be modular. Helper scripts detect the presence of language-specific configuration (for example `Cargo.toml`, `pyproject.toml`, `package.json`) and only run relevant tasks.

- If there is no Rust code, Rust-related tasks are silently skipped.
- If you remove the Python or JS parts, corresponding checks are skipped.
- This supports Python-only, web-only, or fully polyglot projects under the same governance rules.

## Intended audience

This system is optimized for:

- **Teams**: 3+ developers sharing a single codebase.
- **Polyglot codebases**: Python + JS/TS + Rust (with optional PowerShell) under one consistent contract.
- **Organizations**: Standardized CI, formatting, linting, and type-checking across many repos.
- **Windows developers**: Especially Windows 11 + Cursor, with first-class support for WSL2 and PowerShell.

It is **not** ideal for:

- Disposable prototypes or quick one-off scripts.
- Projects that must remain tied to `npm`, `yarn`, or `pnpm` as primary package managers.
- Environments that cannot honor the version pinning and lockfile rules defined in `CONSTITUTION.md`.
