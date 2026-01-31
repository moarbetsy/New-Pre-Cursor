# REPORT.md

Only real breakage; no secrets. Append-only. See AGENT_PROTOCOL.md §4.2.

---

## Issues

### 2026-01-30 (local) — GitHub Actions Precursor CI: File not found precursor.ps1
- **Context:** CI step `bun run precursor.ps1 -Scan --json` on ubuntu-latest.
- **Command / action:** Workflow run from repo root with bash.
- **Observed:** `error: File not found "precursor.ps1"`, exit code 1.
- **Root cause:** (1) Workflow ran at repo root; precursor.ps1 lives in project-doctor/. (2) `bun run` runs package.json scripts or .js/.ts, not .ps1; on Linux the step does not invoke PowerShell.
- **Fix:** Set `defaults.run.working-directory: project-doctor` and run `bun run src/cli.ts scan --json` so the scan runs via the TypeScript CLI on Linux without PowerShell.
- **Prevention:** Use working-directory when the entry point lives in a subdir; use cross-platform CLI (TS/JS) in Linux CI instead of .ps1 unless pwsh is explicitly set up.
- **Status:** resolved

---
