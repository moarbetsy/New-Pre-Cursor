# Workflow

## Local dev (Bun-first)

### Install (deterministic)

```bash
bun install --frozen-lockfile
pipx install "uv==0.9.27"
uv sync --frozen
```

Note (Windows): if you don't use `pipx`, installing `uv` via `python -m pip install "uv==0.9.27"` is also fine.

### Daily commands

```bash
just fmt
just lint
just type
just test
just ci
```

## Python version policy

This repo follows a **\"run newest, typecheck against minimum\"** rule for Python:

- Runtime in CI/dev is pinned to a **newer Python** (currently 3.14.2).
- Tooling (Ruff + Pyright) targets the **minimum supported version** (currently 3.11).

Concretely:

- `.python-version` and `.github/workflows/ci.yml` pin CI/dev to Python **3.14.2**.
- `pyproject.toml` declares `requires-python = \">=3.11,<3.15\"` and `ruff.target-version = \"py311\"`.
- `pyrightconfig.json` sets `\"pythonVersion\": \"3.11\"`.

The guarantee is: if your code typechecks and passes tests here, it is safe to run anywhere in the \">=3.11,<3.15\" range, while CI runs against a realistic, latest-stable runtime.

## CI contract

CI runs `just ci` (check-mode only). If CI fails:

1. run `just ci` locally
2. if failures are formatting/lint, run `just fmt` / `just lint` and commit changes
3. re-run `just ci`

## PowerShell linting

PowerShell scripts in this repo are linted via **PSScriptAnalyzer**, configured by `PSScriptAnalyzerSettings.psd1`.

- `just lint` / `just lint-check` include the `ps-lint` task.
- `ps-lint` runs `Invoke-ScriptAnalyzer` with:
  - `-Path . -Recurse`
  - `-Settings ./PSScriptAnalyzerSettings.psd1`
  - `-EnableExit` (so any violations fail the task/CI).

To change PowerShell lint behavior, edit **only** `PSScriptAnalyzerSettings.psd1` (it is the single source of truth for PS rules and severities).

## “Break-glass Node” usage

Node is allowed ONLY as a runtime fallback, without introducing npm lockfiles.

- Typecheck via Node runtime (still using deps installed by Bun):
  ```bash
  just web-type-node
  ```
- Tests via Node runtime:
  ```bash
  just web-test-node
  ```

If you find a case where Bun fails but Node succeeds, file an issue and capture:

- the command that fails under Bun
- the command that succeeds under Node
- OS + versions (`scripts/doctor.*`)
