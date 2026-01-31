---
description: Mandatory REPORT.md logging and the apply report repair workflow
alwaysApply: true
---

# Issue reporting rule (mandatory)
Whenever an issue occurs in this workspace (tool failure, terminal command failure, install error, config mismatch, unexpected behavior, flaky environment, etc.), you MUST append an entry to REPORT.md in the repository root.

## What to log
Must log:
- Any unexpected non-zero exit code
- Crashes, hangs, timeouts that block work
- Security or permission issues
- Data loss or corruption
- Breaking functional changes

Should log:
- Missing tools or PATH problems
- ExecutionPolicy blocks
- Dependency install failures
- Linter/typecheck failures introduced by changes
- Performance regressions
- Unexpected behavior requiring investigation

Do not log:
- Purely cosmetic issues
- Temporary network issues unless persistent

## How to log (append only)
Append under "## Issues" using:

### YYYY-MM-DD HH:MM (local) — <short descriptive title>
- **Context**: <what you were trying to do>
- **Command / action**: `<exact command or action>`
- **Observed**: <error message / behavior>
- **Root cause**: <what caused this issue>
- **Fix**: <what changed / what to do next>
- **Prevention**: <how to prevent this issue in the future>
- **Status**: resolved | mitigated | unresolved

Rules:
- Do not delete or rewrite REPORT.md history; only append.
- Log each distinct issue separately.
- Always include Prevention.
- Use local time for the timestamp.

# Apply report workflow (mandatory trigger phrase)
When the user says "apply report", do the following:

1) Read REPORT.md.
2) Identify entries with Status = unresolved or mitigated.
3) Fix each issue by:
   - reproducing safely with minimal commands (when feasible)
   - applying a permanent fix (config/script/code change), not a one-off workaround
   - keeping the single-entry run.ps1 pattern
4) Verify by re-running the relevant command(s).
5) Update REPORT.md:
   - do not delete or rewrite history
   - append a new entry for each applied fix if needed
   - add a follow-up note referencing the original issue and set final status to resolved once verified

Constraints:
- Prefer PowerShell 7 commands.
- If a fix requires machine-wide changes (PATH, ExecutionPolicy, installs), document steps and add a project-local mitigation when possible.

# Fail-fast contract
- Any native command must check success ($?) and/or $LASTEXITCODE.
- On failure: stop and report the exact command, exit code, and the next step.
