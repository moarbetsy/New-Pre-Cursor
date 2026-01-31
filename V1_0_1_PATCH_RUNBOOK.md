# V1_0_1_PATCH_RUNBOOK.md

Purpose: a tightening pass focused on **rule integrity**, **truthful verification**, and **predictable execution**.

This runbook is intentionally sequenced so that foundational correctness (policy file integrity) is fixed before anything else.

---

## Step 1 — Stop `.mdc` corruption (foundational)
### Objective
Ensure `.cursor/rules/*.mdc` can never mutate into JSON blobs on reruns.

### Constraints
- `.mdc` must stay **Markdown + YAML frontmatter** (never JSON).
- The change must be idempotent.

### Plan
1) Identify where `.mdc` generation routes through JSON merge logic.
2) Replace that flow with **owned overwrite** or **managed blocks**.
3) Add a safety check that flags `.mdc` JSON objects as corruption.

### Verification
- Run scaffold twice; second run produces no `.mdc` format drift.
- Confirm `.mdc` begins with `---` and contains Markdown (not JSON).

---

## Step 2 — Repair current `.mdc` outputs
### Objective
Convert any existing JSON-wrapped rule files back into valid Cursor `.mdc` files.

### Plan
1) Rewrite corrupted `.mdc` files as Markdown with YAML frontmatter.
2) Add managed-block markers if using the managed-block strategy.

### Verification
- No `.mdc` contains `{ "content": ... }`.
- Cursor rules load as Markdown.

---

## Step 3 — Unify Python policy with actual stack (uv + ruff + pyright)
### Objective
Remove internal contradictions (e.g., mypy strict references) and align rules with config.

### Plan
1) Make **one** Python rule file the source of truth (e.g., `python.mdc`).
2) Ensure commands and tooling references match `precursor.json`.

### Verification
- Python policy references uv + ruff + pyright (or basedpyright if configured).
- No stray mypy requirements unless explicitly configured.

---

## Step 4 — Version-gate Python 3.14 guidance
### Objective
Keep 3.14+ guidance without misleading repos that target older Python.

### Plan
1) Detect target Python from:
   - `pyproject.toml` `project.requires-python`, else
   - `.python-version`, else
   - explicit operator instruction.
2) Only apply 3.14-only sections if target >= 3.14.

### Verification
- For targets < 3.14, 3.14-only directives are inactive or clearly marked “ignore.”

---

## Step 5 — Make Windows rules conditional / capability-based
### Objective
Avoid unconditional “Windows-only forever” policy if the product claims cross-platform support.

### Plan
1) Replace OS-religion rules with capability rules:
   - If Windows → pwsh
   - If Unix → bash/zsh
2) Generate only the relevant system rule based on detection OR set alwaysApply appropriately.

### Verification
- On Windows, PowerShell instructions remain enforced.
- On non-Windows, policy does not hard-ban shell tooling.

---

## Step 6 — Preserve exit codes (remove `|| true` masking)
### Objective
Make verification truthful; separate “allowed failure” policy from raw truth.

### Plan
1) Remove `|| true` from default verification commands.
2) If needed, add config-level policy:
   - `verification.failOnError`
   - `verification.allowFailures: [...]`

### Verification
- A failing test produces a failure signal that can be detected.
- If “allowed,” it is still reported as failed, but policy may allow continuation.

---

## Step 7 — Normalize Windows paths for secrets ignore patterns
### Objective
Make ignore patterns work correctly on Windows (avoid scanning huge trees).

### Plan
1) Normalize scanned file paths to forward slashes before glob matching.
2) Normalize ignore patterns the same way.

### Verification
- `**/node_modules/**` matches on Windows paths.
- Scanning is faster and less noisy.

---

## Step 8 — Make `workspaceRoot` first-class everywhere
### Objective
Eliminate root/cwd inconsistency (especially in monorepos and subprojects).

### Plan
1) Determine `workspaceRoot` once.
2) Pass it through detector/doctor/scaffold/verification.
3) Write generated artifacts relative to `workspaceRoot` unless configured otherwise.

### Verification
- Running from subdirectories writes to the intended root.
- Re-running from different cwd yields the same outputs.

---

## Done criteria
- `.mdc` files remain Markdown with YAML frontmatter.
- Python/web rule sets match actual tooling.
- Verification reports real failures honestly.
- Secrets scanning ignores work on Windows.
- Root handling is consistent and idempotent.
