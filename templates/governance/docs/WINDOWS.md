# Windows 11 Pro + Cursor

## Route A (best): WSL2 as your “dev OS”

Why this wins: best parity with Linux CI, saner paths/quoting, fewer polyglot toolchain edge cases.

- Install WSL2 + Ubuntu
- Install inside WSL:
  - Bun
  - Python tooling (pipx + uv)
  - Rust (rustup)
  - just
- Open repo in Cursor using Remote/WSL
- Run:
  ```bash
  bun install --frozen-lockfile
  pipx install "uv==0.9.27"
  uv sync --frozen
  just ci
  ```

## Route B (fallback): Native Windows + PowerShell 7

This repo’s `justfile` uses **PowerShell 7** on Windows.

- Install PowerShell 7 so `pwsh` is on PATH
- Install `just` (for example via winget)
- If lockfiles are missing (common when starting from a template zip), run:
  ```powershell
  just bootstrap
  ```
- Run:
  ```powershell
  bun install --frozen-lockfile
  uv sync --frozen
  just ci
  ```

## Node break-glass

If you hit a Bun runtime compatibility issue, Node is allowed as a runtime fallback.
Do NOT use npm to install deps and do NOT commit npm lockfiles.
