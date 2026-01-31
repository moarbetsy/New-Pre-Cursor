# STEPLOG.md (append-only)

Purpose: a deterministic audit trail of agent work, recorded step-by-step.

Rules:
- Append-only. Never rewrite history.
- One entry per step (including “no-change” and “aborted” steps).
- Never include secrets/tokens/keys/connection strings/`.env` values.
- Keep it concise. Link to REPORT.md / INCIDENTS.md instead of duplicating long logs.

---

## Session: 2026-01-30 — <Task title>
Owner: <agent/human>
Repo state: <branch> @ <commit hash if known>

### Step 1 — <Short step title>
- **Objective:** <1 sentence>
- **Scope:**
  - <max 3 bullets>
- **Files changed:**
  - <path> — <why>
- **Commands run (exact):**
  - `<command>` → exit <code>
- **Result:** <pass/fail + one line summary>
- **Verification:** <what “pass” meant here>
- **Notes:** <only if needed; no secrets>
- **Next:** <continue to Step 2 | stop>
- **Refs:**
  - REPORT.md: <entry title/date> (if relevant)
  - INCIDENTS.md: <entry title/date> (if relevant)

---
