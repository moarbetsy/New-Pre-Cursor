# Contributing

Thank you for your interest in contributing! This repository follows a strict governance model to ensure consistency and maintainability.

## Before You Start

1. **Read the Constitution**: Start with [`CONSTITUTION.md`](CONSTITUTION.md) to understand the core principles
2. **Understand Ownership**: Review [`docs/OWNERSHIP.md`](docs/OWNERSHIP.md) for the "one rewriter per extension" rule
3. **Check Workflow**: See [`docs/WORKFLOW.md`](docs/WORKFLOW.md) for daily development practices
4. **Windows Users**: Read [`docs/WINDOWS.md`](docs/WINDOWS.md) for platform-specific guidance

## Development Setup

### First-Time Setup

```bash
bun install --frozen-lockfile
pipx install "uv==0.9.27"
uv sync --frozen
just ci
```

Or use the bootstrap command:

```bash
just bootstrap
```

### Verify Your Environment

Run the doctor command to check your tooling:

```bash
just doctor          # Unix/macOS/WSL
just doctor-windows  # Native Windows PowerShell
```

## Daily Workflow

### Before Making Changes

1. Ensure your environment is set up correctly: `just doctor`
2. Make sure you're on the latest main branch
3. Create a feature branch

### While Developing

- **Format code**: `just fmt` (rewrites files)
- **Lint code**: `just lint` (autofixes where possible)
- **Type check**: `just type` (read-only)
- **Run tests**: `just test`

### Before Committing

**Always run `just ci` before committing.** This runs all checks in read-only mode (what CI will run):

```bash
just ci
```

If `just ci` fails:

1. Fix formatting: `just fmt`
2. Fix linting: `just lint`
3. Fix type errors
4. Fix failing tests
5. Run `just ci` again until it passes

## Code Style and Tooling

### The Boss Rule

**One rewriter per file extension.** Many tools may check, but only one tool may rewrite:

- `*.py` → Ruff (format + lint)
- `*.ts, *.js, *.json` → Biome (format + lint)
- `*.md, *.yaml, *.toml` → dprint (format)
- Rust → `cargo fmt` (format), `clippy` (lint)

### Lockfile Policy

- **JS**: Only `bun.lock` is allowed. Never commit `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`
- **Python**: `uv.lock` is required if `pyproject.toml` exists
- Always use `--frozen-lockfile` / `--frozen` flags

### Tool Versions

All tool versions are pinned:

- Bun: `.bun-version`
- Python: `.python-version`
- Rust: `rust-toolchain.toml`

Never use floating "latest" versions.

## Pull Request Process

1. **Ensure CI passes**: Your PR must pass `just ci`
2. **Keep PRs focused**: One logical change per PR
3. **Update documentation**: If you change behavior, update relevant docs
4. **Follow ownership rules**: Don't introduce conflicting formatters/linters

## Customizing This Template

This is a template repository. When adapting it for your project:

1. **Delete what you don't need**: Remove unused language configs (`Cargo.toml`, `pyproject.toml`, etc.)
2. **Update ownership map**: Adjust `docs/OWNERSHIP.md` if you change tooling
3. **Update lockfile laws**: Ensure `justfile` rules match your mandatory vs optional stacks
4. **Update CI**: Adjust `.github/workflows/ci.yml` for your needs

## Questions?

- Check [`docs/GOVERNANCE_GRAPH.md`](docs/GOVERNANCE_GRAPH.md) for visual overview
- Review existing code for patterns
- Open an issue for clarification

## Security

See [`SECURITY.md`](SECURITY.md) for security reporting procedures.
