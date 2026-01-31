---
name: doctor
description: Diagnose and repair dev environment; run project doctor when tools or commands fail
---
# Doctor Skill
## When to use
- Commands hang or fail
- Tools missing from PATH
## Procedure
1) Run: `precursor.ps1 -Setup` (or `bun run src/cli.ts setup` from project-doctor)
2) If using setup-cursor: `cursorkit -Doctor` then `cursorkit -Setup` if tools missing
