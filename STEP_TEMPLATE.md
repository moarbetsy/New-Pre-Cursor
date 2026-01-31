# STEP_TEMPLATE.md

Use this exact structure for each step. Don’t skip sections.

---

## Step N — <Short title>

### Objective
One sentence.

### Constraints (MUST obey)
- List only the relevant MUST items for this step.
- Include “don’t corrupt .mdc” if touching rule generation.

### Inputs checked
- Workspace root:
- Relevant config files read:
- Relevant existing rules/scripts read:

### Plan (max 3 bullets)
Keep it small and testable.

### Changes (explicit)
List files changed + why:
- path — reason

### Commands run (exact)
Paste exact commands used.

### Results
- Exit codes:
- Key output (brief):

### Verification
What “pass” means for this step.

### Rollback
If needed, what gets reverted.

### Step Ledger update
Append one entry to STEPLOG.md for this step:
- objective
- files changed
- commands + exit codes
- verification result
- decision (continue/stop)

### Decision
- ✅ Continue to Step N+1
- 🛑 Stop (why)
