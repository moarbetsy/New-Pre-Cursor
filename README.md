# Complete Cursor + Governed Stack Project

This repo is the **complete project** assembled from the three complementary tools described in `GITHUB_REPOS_COMPREHENSIVE_ANALYSIS.md`:

- **Machine setup** → `machine-setup/` (Windows + Cursor + UV/Bun/Git, project template)
- **Project doctor and Cursor** → `project-doctor/` (Precursor: rules, MCP, CI, scaffold)
- **New governed repo** → `templates/governance/` (justfile, CONSTITUTION, lockfile law, polyglot template)

---

## Layout

| Directory | Purpose | Entry point |
|-----------|---------|-------------|
| **machine-setup/** | Windows dev environment installer; winget-like setup for Cursor + UV/Bun/Git + project templates | `run.ps1`, `setup-cursor -Setup` |
| **project-doctor/** | Config-driven project doctor + Cursor scaffolder (rules, MCP, CI, idempotent bootstrap) | `precursor.ps1 -Setup`, `bun run src/cli.ts setup` |
| **templates/governance/** | Governance contract + polyglot template (just, CONSTITUTION, one rewriter per extension) | `just ci`, clone as new project base |

---

## When to use what

| Goal | Use |
|------|-----|
| Set up Windows + Cursor + UV/Bun/Git and get a project template | **machine-setup/** |
| Add Cursor rules, MCP, CI workflows, and project doctor to an existing repo | **project-doctor/** |
| Start a new repo with strict governance (lockfiles, one rewriter per extension, just) | **templates/governance/** |
| Full workflow: install environment, then add Cursor/CI to a governed repo | **machine-setup** then **project-doctor** (optionally start from **templates/governance**) |

---

## Quick start

### One-command setup (new machine)

On a new computer with a new Cursor account:

```powershell
winget install PreCursor.PreCursor; precursor -Setup
```

Or fallback (no winget package yet): `irm https://raw.githubusercontent.com/MoarBetsy/New-Pre-Cursor/main/bootstrap.ps1 | iex`. See **COMMANDS.md** for prerequisites and details.

### Machine setup (Windows)

```powershell
cd machine-setup
.\install-global.ps1 -Method PowerShellProfile   # or clone and run from here
setup-cursor -Setup
setup-cursor -NewProject "my-app"
cd my-app
```

### Project doctor (any repo)

```powershell
cd your-existing-repo
# Copy or run project-doctor from here:
..\project-doctor\precursor.ps1 -Setup
# Or: cd project-doctor && bun run src/cli.ts setup
```

### New governed project

```powershell
# Copy the governance template as your new project root
xcopy /E /I templates\governance my-new-project
cd my-new-project
bun install --frozen-lockfile
uv sync --frozen
just ci
# Then add Cursor rules: ..\project-doctor\precursor.ps1 -Setup
```

---

## Docs and protocol

- **GITHUB_REPOS_COMPREHENSIVE_ANALYSIS.md** — Full analysis of the three repos, integration, usage guides, and recommendations.
- **AGENT_PROTOCOL.md** — Agent operating rules (verification, idempotency, no .mdc corruption).
- **STEPLOG.md** — Audit trail of agent steps; **REPORT.md** — Real breakage only.
- **WINGET_PUBLISH.md** — How to publish the winget package (release, ZIP, manifest, winget-pkgs).

Repo URLs use GitHub owner **MoarBetsy**; change if you fork.

---

*Machine setup → machine-setup. Project doctor and Cursor → project-doctor. New governed repo → clone templates/governance.*
