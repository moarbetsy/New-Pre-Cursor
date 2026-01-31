# AGENT_PLAYBOOK.md — Precursor / Repo Governance Agent Manual

This document defines the **only acceptable workflow** for making changes in this repo.
It is designed to prevent "agent drift", skipped verification, and policy/file-format corruption.

---

## 0) Mission

You are maintaining a **policy-driven repo governor**:
- deterministic scaffolding
- predictable toolchain use
- auditable changes
- safety rails for AI-assisted development

Your job is **not** to be clever. Your job is to be **boringly correct**.

---

## 1) Non-negotiable laws (MUST)

### 1.1 One entry point
- If `run.ps1` exists: **route work through it**.
- Otherwise, use `precursor.ps1` as the orchestrator.
- Do not instruct humans to run 12 ad-hoc commands. Prefer **one** command that calls others.

### 1.2 Idempotency
- Any setup/scaffold action must be safe to run twice:
  - second run should produce **no diffs** or only stable, deterministic formatting.

### 1.3 File formats are sacred
- **Never** treat Markdown as JSON.
- Cursor rule files (`.cursor/rules/*.mdc`) must remain **Markdown + YAML frontmatter**.
- If a `.mdc` file becomes a JSON object like `{ "content": "..." }`, that is a **critical bug** and must be corrected immediately.

### 1.4 Don't hide failures
- Do not mask exit codes.
- Never use `|| true` / "force success" patterns.
- Verification must preserve the real success/failure signal.

### 1.5 Don't leak secrets
- Never paste tokens, keys, `.env` values, connection strings, or high-entropy strings into:
  - `REPORT.md`, `INCIDENTS.md`, issues, commit messages, or chat logs.
- If you must report, redact values: `abcd...wxyz` or `[REDACTED]`.

### 1.6 Lockfile law
- Do not introduce new lockfiles from a different tool (e.g., npm lockfile in a Bun repo).
- Do not delete lockfiles.
- Only update lockfiles via the blessed toolchain.

---

## 2) Source of truth hierarchy (in order)

1) `precursor.json` (repo policy configuration)
2) existing scripts (`run.ps1`, `precursor.ps1`)
3) existing Cursor rules (`.cursor/rules/*.mdc`)
4) repo docs (`README.md`, `CONTRIBUTING.md`, governance constitution)

If any two sources conflict, resolve by updating the **highest-ranked** source first.

---

## 3) The Golden Path workflow (small steps, always verifiable)

Each task must follow these stages. Do not skip stages.

### Stage A — Preflight (no changes)
1) Determine workspace root:
   - Prefer git root (`git rev-parse --show-toplevel`) when available.
2) Identify stacks present (Python/web/rust/cpp/docker).
3) Read `precursor.json` and summarize the *active* toolchain choices.

**Output:** a short "Preflight Summary" in your working notes (not `REPORT.md`).

---

### Stage B — Plan (before editing)
Create a **change plan** with:
- Goal (1 sentence)
- Files to modify (explicit list)
- Update strategy per file (see Section 4)
- Verification commands to run
- Rollback strategy (what to revert if it goes wrong)

Keep the plan small. If the plan has more than ~5 files, split into multiple steps.

---

### Stage C — Implement Step 1 (minimum viable change)
1) Make the smallest change that advances the goal.
2) Keep diffs tight:
   - No drive-by refactors.
   - No "while I'm here" changes.
3) If touching policy/rules/scaffolding, use the **correct update strategy** (Section 4).

---

### Stage D — Verify (immediately)
Run the verification commands you listed in the plan.
- Preserve real exit codes.
- Capture concise output.

If verification fails:
- Do not keep piling changes on top.
- Enter the **Failure Loop** (Section 6).

---

### Stage E — Document outcomes
- Only log to `REPORT.md` if something is actually broken (non-zero exit code, blocked workflow, corruption risk).
- If you fixed a `REPORT.md` item, append a follow-up note and mark it resolved **only after verification**.

---

### Stage F — Repeat in steps
Repeat C→D→E until goal is done.

**Definition of done:** see Section 7.

---

## 4) File update strategies (choose the right one)

### 4.1 Structured config files (JSON/YAML/JSONC)
✅ Allowed: deep merge, preserve unknown keys
Tooling: `merge.ts` deep merge engine is appropriate here.

Examples:
- `precursor.json`
- `pyproject.toml` (TOML is structured; treat carefully—prefer minimal edits)
- `tsconfig.json`, `biome.json`, `pyrightconfig.json`

---

### 4.2 Cursor rule files (`.mdc`) — CRITICAL
🚫 Forbidden: JSON merge / JSON parsing / treating `.mdc` as data

✅ Allowed strategies (pick one):

**Strategy A — Owned files (overwrite)**
- Precursor "owns" these files and rewrites them fully on each run.
- User customization goes in a separate untouched file:
  - `.cursor/rules/local-overrides.mdc`

**Strategy B — Managed blocks (recommended)**
Maintain a stable rule file and update only a fenced region:

```md
<!-- PRECURSOR:BEGIN <rule-id> -->
...generated content...
<!-- PRECURSOR:END <rule-id> -->
```

Rules:
- Preserve YAML frontmatter.
- Never touch content outside the managed block.
- If markers are missing, add them explicitly once; do not "guess merge."

---

### 4.3 Append-only logs
- `REPORT.md`, `INCIDENTS.md`, and `STEPLOG.md` are append-only.
- Never rewrite history; add follow-ups referencing earlier entries.

---

## 5) Reporting: what goes where

### 5.1 STEPLOG.md (mandatory every step)
- One entry per step, even "no change" or "aborted."
- Must include commands + exit codes and verification result.
- Keep it concise; link out to REPORT/INCIDENTS for details.

### 5.2 REPORT.md (only real breakage)
Use REPORT.md for:
- Non-zero exit codes that block normal work
- Broken workflows (install, build, test, lint)
- Tooling drift
- Corruption risks (like `.mdc` becoming JSON)

### 5.3 INCIDENTS.md (agent behavior failures)
Use INCIDENTS.md for:
- Policy contradictions introduced
- Repeated failure loops / flailing
- Violations of Tier 1–2 rules
- The rule change that would prevent recurrence

---

## 6) Failure Loop (when verification fails)

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

## 7) Definition of done

A step (or runbook) is done when:

- **Verification passed:** All planned verification commands ran and reported success (real exit codes preserved).
- **Ledger updated:** STEPLOG.md has an entry for the step (objective, files changed, commands + exit codes, verification result).
- **No new breakage:** REPORT.md is updated only if something was fixed (with a follow-up) or a new block was discovered.
- **Policy intact:** No `.mdc` corruption; no secret leakage; lockfiles unchanged except via blessed toolchain.

Stop and ask for direction if:
- Required inputs can't be inferred from repo config
- A fix would broaden scope beyond the current step
- A change impacts security/supply-chain unexpectedly

Boring is beautiful. Determinism is mercy.
