# AGENT_PROTOCOL.md

This repo is a **policy-driven “repo governor”** for AI-assisted software work.
The point is to make changes **boring, repeatable, auditable, and safe**.

This document defines the operating rules for any coding agent working here.

---

## 0) Priority tiers

Agents follow instructions better when the rules have explicit priority.

### Tier 1 — NON‑NEGOTIABLE (MUST)
Violating these is a *stop event*.

1) **Truthful verification**
   - Never mask failures (no `|| true`, no “ignore exit code”).
   - Preserve real exit codes.
   - “Policy about allowed failures” is separate from truth.

2) **Idempotency**
   - Setup/scaffold tasks must be safe to rerun.
   - Rerun should produce **no diffs** (or only stable formatting diffs).

3) **Single command surface**
   - Prefer the repo’s entry point (e.g., `run.ps1`, `precursor.ps1`, or a `justfile`).
   - Avoid ad‑hoc command soups.

4) **Cursor rules integrity (`.mdc` files)**
   - `.cursor/rules/*.mdc` must remain **Markdown with YAML frontmatter**.
   - Never deep-merge `.mdc` as JSON/JSONC/YAML.
   - If a `.mdc` becomes a JSON blob like `{ "content": "..." }`, treat it as **policy corruption** and fix immediately.

5) **No secret leakage**
   - Never paste tokens, keys, `.env` contents, connection strings, or high-entropy strings into:
     - `REPORT.md`, `INCIDENTS.md`, `STEPLOG.md`, commits, issues, chat logs.
   - Redact aggressively (`abcd…wxyz` or `[REDACTED]`).
   - Log *where* it was found and the pattern type, not the value.

6) **Lockfile law**
   - Do not introduce new lockfiles from different tooling (e.g., npm lockfile in a Bun repo).
   - Do not delete lockfiles.
   - Only update lockfiles via the blessed toolchain.

---

### Tier 2 — DEFAULT POLICY (SHOULD)
Follow unless repo config explicitly overrides.

1) **Minimize blast radius**
   - Each step changes as few files as possible.
   - No drive-by refactors.

2) **Read before write**
   - Prefer inspecting repo reality (config/scripts) over guessing.

3) **Consistency with repo config**
   - Tooling rules must match `precursor.json` and existing conventions.
   - Do not introduce contradictions (e.g., mypy requirements if the repo uses pyright).

4) **Capability rules > OS religion**
   - Prefer “if Windows → pwsh; if Unix → bash/zsh” over unconditional bans.

---

### Tier 3 — ESCAPE HATCHES (MAY, ONLY IF LOGGED)
If you must break a SHOULD rule, log a short justification.

Allowed examples:
- Temporary workaround for a known upstream bug
- One-off manual step required by the operator’s environment
- Known flaky test temporarily tolerated (but failure still recorded truthfully)

Escape hatches never permit violating Tier 1.

---

## 1) Golden workflow (work in many steps)

All work is executed as **Step 1, Step 2, ...**.
Every step ends with verification and a ledger entry.

### 1.1 The step cycle
1) **Preflight** (read-only)
2) **Plan** (small, testable)
3) **Implement** (minimum viable change)
4) **Verify** (commands + exit codes)
5) **Log** (STEPLOG.md; plus REPORT.md/INCIDENTS.md if needed)

Use `STEP_TEMPLATE.md` for each step.

---

## 2) Failure Loop (deterministic ritual)

When a command fails unexpectedly:

1) **STOP**. Do not stack more changes.
2) Record the minimal repro context (no secrets).
3) Run preflight checks:
   - `Get-Command <tool>`
   - `where.exe <tool>`
4) Retry exactly once after the smallest plausible fix.
5) If still failing: propose the minimal permanent fix.

Log to `REPORT.md` only if:
- It blocks progress, or
- It risks corruption/data loss.

---

## 3) File update strategies

### 3.1 Structured config (JSON/JSONC/YAML/TOML)
- Deep merge is allowed where appropriate.
- Preserve unknown keys.
- Keep edits minimal and stable.

### 3.2 Cursor rule files (`.cursor/rules/*.mdc`) — special handling
Never deep-merge `.mdc`. Pick one:

**Option A — Owned files (overwrite)**
- Precursor owns these `.mdc` files and rewrites them fully each run.
- User customization lives in `.cursor/rules/local-overrides.mdc` (never touched).

**Option B — Managed blocks (recommended)**
Update only a fenced region:

```md
<!-- PRECURSOR:BEGIN <id> -->
...generated content...
<!-- PRECURSOR:END <id> -->
```

Rules:
- Preserve YAML frontmatter.
- Never touch content outside the managed block.
- If markers are missing, add them explicitly once; do not “guess merge.”

### 3.3 Append-only logs
- `REPORT.md`, `INCIDENTS.md`, and `STEPLOG.md` are append-only.
- Never rewrite history; add follow-ups referencing earlier entries.

---

## 4) Reporting: what goes where

### 4.1 STEPLOG.md (mandatory every step)
- One entry per step, even “no change” or “aborted.”
- Must include commands + exit codes and verification result.
- Keep it concise; link out to REPORT/INCIDENTS for details.

### 4.2 REPORT.md (only real breakage)
Use REPORT.md for:
- Non-zero exit codes that block normal work
- Broken workflows (install, build, test, lint)
- Tooling drift
- Corruption risks (like `.mdc` becoming JSON)

### 4.3 INCIDENTS.md (agent behavior failures)
Use INCIDENTS.md for:
- Policy contradictions introduced
- Repeated failure loops / flailing
- Violations of Tier 1–2 rules
- The rule change that would prevent recurrence

---

## 5) Stop conditions (anti-hallucination guardrails)

Stop and ask for direction (or propose minimal options) if:
- Required inputs can’t be inferred from repo config
- A fix would broaden scope beyond the current step
- A change impacts security/supply-chain unexpectedly
- You’re about to “upgrade the world” instead of fixing the target

Boring is beautiful. Determinism is mercy.
