# All commands (reference)

Commands available in this project, by entry point. Use from the **directory** shown.

---

## One-command setup (new machine)

On a **new computer with a new Cursor account**, run one of the following to get the full PreCursor setup (Cursor IDE, repo, UV/Bun/Git, governance rules, project-doctor).

**Prerequisites:** PowerShell 7, winget, network. Git is required for the winget launcher (clone step).

### Primary (winget + setup)

```powershell
winget install PreCursor.PreCursor; precursor -Setup
```

After the package is published to winget-pkgs, the above installs the `precursor` command and runs full bootstrap. If the package is not yet in winget, use the fallback below.

### Fallback (no winget package)

Download and run the repo bootstrap script (installs Cursor, clones this repo to `$env:USERPROFILE\PreCursor`, runs machine-setup and project-doctor):

```powershell
irm https://raw.githubusercontent.com/MoarBetsy/New-Pre-Cursor/main/bootstrap.ps1 | iex
```

Repo: **MoarBetsy/New-Pre-Cursor**. The script will clone the repo if not present; ensure Git is installed.

### After setup

- Open the repo folder in Cursor: **`$env:USERPROFILE\PreCursor`** (or the path printed by the script).
- From any terminal: `setup-cursor -Setup` for full machine-setup in a project; `setup-cursor -NewProject "my-app"` to create a new project.

---

## One command: setup and test everything

From the **repo root** (New Pre-Cursor):

```powershell
.\setup-and-test.ps1
```

Runs in order:
1. **Project doctor setup** (scaffold, verification, CI, secrets check)
2. **Project doctor unit tests** (`bun test`)
3. **Governance template CI** (`just ci` in `templates/governance`) if `just` is installed; otherwise skips with a message.

Exit code 0 = all passed; non-zero = at least one step failed.

---

## 1) Project doctor / Precursor

**Where:** `project-doctor/` (or `_analysis_precursor/`)

**CLI (Bun):**
```powershell
cd project-doctor
bun run src/cli.ts <command> [options]
```
| Command   | Description                          |
|-----------|--------------------------------------|
| `setup`   | Idempotent bootstrap (rules, MCP, CI, scaffold) |
| `scan`    | Read-only doctor scan → JSON         |
| `rollback`| Restore latest backup snapshot       |
| `reset`   | Wipe state cache                     |

**Options (global):** `--strict`, `--offline`, `--json`, `--no-color`

**PowerShell wrapper:**
```powershell
cd project-doctor
.\precursor.ps1 -Setup | -Scan | -Rollback | -ResetState | -Update
.\precursor.ps1 -Strict | -Offline | -Json | -NoColor
```

**package.json scripts (from project-doctor):**
| Script     | Command                    |
|------------|----------------------------|
| `build`    | `bun build src/index.ts --outdir dist --target bun` |
| `test`     | `bun test`                 |
| `lint`     | `bunx biome check .`      |
| `format`   | `bunx biome format --write .` |
| `typecheck`| `tsc --noEmit`             |

**Run setup from repo root (for another repo):**
```powershell
cd your-existing-repo
..\project-doctor\precursor.ps1 -Setup
# Or: cd project-doctor && bun run src/cli.ts setup
```

---

## 2) Setup Cursor / Machine setup (run.ps1)

**Where:** `_analysis_setup_cursor/` or `machine-setup/`

**Entry point:**
```powershell
cd _analysis_setup_cursor   # or machine-setup
.\run.ps1 [switches]
```

| Switch | Description |
|--------|-------------|
| `-Setup` | Full setup: install tools, fix issues, venv, deps, Cursor settings, MCP, bootstrap, doctor |
| `-InstallTools` | Install UV, Bun, Git via winget |
| `-UpdatePython` | Update Python/pip/uv and deps from requirements.txt |
| `-FixIssues` | Apply REPORT.md-style fixes (PowerShell extension, execution policy, etc.) |
| `-ApplyAllSettings` | Cursor settings + IntelliSense + IDE file exclusions |
| `-ApplyCursorSettings` | Only merge Cursor settings from template |
| `-SetupMCP` | Configure MCP servers under `.cursor/mcp` |
| `-Doctor` | Environment diagnostics (PowerShell, tools, PATH, Cursor) |
| `-Bootstrap` | Create .gitignore, README.md, REPORT.md, cursor-settings if missing |
| `-Clean` | Remove .venv, node_modules, dist, build, __pycache__, etc. |
| `-NewProject <name>` | Copy project to `-DestinationRoot` (default `$HOME\Desktop`) and bootstrap |
| `-PreflightOnly` | Tool checks and exit 0 |
| *(none)* | If main.py exists: run it; else if package.json: `bun run dev`; else interactive dashboard |

**Dashboard options (when no main.py/package.json):**
1. Run Python entrypoint (main.py)
2. Run JS entrypoint (bun run dev)
3. Apply Cursor/VSCode settings
4. Clean project
5. Reveal hidden files
6. Comprehensive setup
7. Install/update dev tools
8. Update Python environment
9. Apply known issue fixes
Q. Quit

---

## 3) Governance template (justfile)

**Where:** `templates/governance/` or `_analysis_governance/`

**Prereq:** `just` installed. Default recipe: `ci`.

```powershell
cd templates\governance
just [recipe]
```

| Recipe | Description |
|--------|-------------|
| **Default / CI** | |
| `ci` | js-lockfile-law, py-lockfile-law, fmt-check, lint-check, type, test |
| **Lockfile** | |
| `js-lockfile-law` | `bun run --silent lockfile:check` |
| `py-lockfile-law` | Run py lockfile check if pyproject.toml |
| **Python** | |
| `py-fmt` / `py-fmt-check` | ruff format / check |
| `py-lint` / `py-lint-check` | ruff check (fix / check) |
| `py-type` | pyright |
| `py-test` | pytest via script |
| **Web (Bun)** | |
| `web-fmt` / `web-fmt-check` | biome fmt / check |
| `web-lint` / `web-lint-check` | biome lint / check |
| `web-type` | package typecheck |
| `web-test` | package test |
| `web-type-node` / `web-test-node` | node-only variants |
| **Docs** | |
| `docs-fmt` / `docs-fmt-check` | dprint |
| **Rust** | |
| `rs-fmt` / `rs-fmt-check` | cargo fmt |
| `rs-lint` | cargo clippy |
| `rs-test` | cargo test |
| **PowerShell** | |
| `ps-lint` | PSScriptAnalyzer |
| **Doctor** | |
| `doctor` | bash ./scripts/doctor.sh |
| `doctor-windows` | pwsh ./scripts/doctor.ps1 |
| **Clean** | |
| `clean` | Remove node_modules, .venv, target, caches, dist, build |
| `clean-windows` | Same via PowerShell |
| **Meta** | |
| `fmt` | py-fmt, web-fmt, docs-fmt, rs-fmt |
| `fmt-check` | All fmt-check recipes |
| `lint` | py-lint, web-lint, rs-lint, ps-lint |
| `lint-check` | All lint-check |
| `type` | py-type, web-type |
| `test` | py-test, web-test, rs-test |
| `bootstrap` | bun install, uv lock, uv sync |

---

## 4) Cursor / IDE

**Slash commands (this repo):**
No custom commands configured. `.cursor/rules/commands.mdc` says: add to `precursor.json` or `.precursor/commands/*.json`.

**Agent protocol (manual):**
See `AGENT_PROTOCOL.md` and `AGENT_PLAYBOOK.md`. Task prompt: follow protocol, use STEP_TEMPLATE, append STEPLOG after each step, no shell profile changes, failure → REPORT.md.

---

## 5) Quick reference by goal

| Goal | Where | Command |
|------|--------|---------|
| Bootstrap Cursor rules + CI in a repo | project-doctor | `.\precursor.ps1 -Setup` or `bun run src/cli.ts setup` |
| Full Windows + Cursor + UV/Bun setup | _analysis_setup_cursor / machine-setup | `.\run.ps1 -Setup` |
| New project from setup template | _analysis_setup_cursor | `.\run.ps1 -NewProject "my-app"` |
| Environment check | _analysis_setup_cursor | `.\run.ps1 -Doctor` |
| Run governance CI (fmt, lint, type, test) | templates/governance | `just` or `just ci` |
| Rollback precursor changes | project-doctor | `bun run src/cli.ts rollback` |
