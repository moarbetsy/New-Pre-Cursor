# Governance System Template — Bun-first + Node break-glass

## 1) Runtime Contract

- **Python:** >=3.11,<3.15 (pinned patch in CI via setup-python)
- **Bun:** pinned via `.bun-version` (default JS runtime + package manager)
- **Node:** 24.x **break-glass runtime only** (never the package manager)
- **Rust:** pinned via `rust-toolchain.toml`
- **PowerShell:** pwsh (minimum version documented; CI image must match)

Rule: Dev and CI must match this contract. No "close enough" versions.

Python policy note: we may run a newer Python in CI/dev for realism, but we typecheck/target the **minimum supported Python** (currently 3.11) in tooling configs unless explicitly stated otherwise.

## 2) Toolchain (Pinned)

- Python rewrite (format + lint + imports): **Ruff**
- Python types: **Pyright**
- Python tests: **pytest**
- Web rewrite (format + lint): **Biome**
- Web types: **TypeScript (tsc)**
- Web tests: **Vitest**
- Docs/data rewrite (Markdown/YAML/TOML): **dprint**
- Rust format: **cargo fmt**
- Rust lint: **clippy**
- PowerShell lint: **PSScriptAnalyzer**

Rule: Tool versions are pinned (lockfiles/config). No floating "latest".

## 3) Ownership Map (One Rewriter Per Extension)

Rewriter ownership (rewrite == format/fix-on-write/fix):

- `*.py` → Ruff
- `*.ts, *.tsx, *.js, *.jsx, *.json` → Biome
- `*.css, *.scss, *.sass, *.html` → Biome (**explicitly enabled in `biome.json`**)
- `*.md, *.yaml, *.yml, *.toml` → dprint
- Rust formatting → `cargo fmt`
- PowerShell → lint via PSScriptAnalyzer (format optional)

Boss Rule: Many checkers are fine. Only ONE tool rewrites a given extension.
Example: ESLint/stylelint allowed only in check mode (no `--fix`) if Biome owns rewrites.

## 4) Lockfile Law

- JS dependencies are installed ONLY via Bun.
- The ONLY committed JS lockfile is `bun.lock`.
- `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `npm-shrinkwrap.json` are forbidden.
- Python dependencies are installed ONLY via `uv`.
- The required Python lockfile is `uv.lock`.

## 5) Merge Gates (minimum)

- fmt-check
- lint-check
- type
- test
- build (only if you ship artifacts)

## 6) Canonical Commands

One command surface for humans + CI:

- `just fmt` / `just fmt-check`
- `just lint` / `just lint-check`
- `just type`
- `just test`
- `just ci`

Policy: CI never writes. CI judges.

## 7) Generated Code Policy

Default:

- `generated/` is excluded from format/lint/type/test unless explicitly validated.
