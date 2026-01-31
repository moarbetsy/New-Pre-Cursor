# Issue Report

## Issues

### 2026-01-24 06:09 (local) — ENOENT error when creating directories during -Setup
- **Context**: Running `.\precursor.ps1 -Setup` to set up the project
- **Command / action**: `.\precursor.ps1 -Setup`
- **Observed**: `ENOENT: no such file or directory, mkdir` error at `merge.ts:122` when trying to create directory for root-level files like `.gitignore`
- **Root cause**: 
  1. `dirname()` of root-level files like `.gitignore` returns `.` (current directory), and `mkdirSync(".", { recursive: true })` can fail on Windows in certain edge cases
  2. `mergeFile` was being used for text files (`.gitignore`, `.cursorignore`) which are not JSON/YAML, causing incorrect serialization attempts
- **Fix**: 
  1. Updated `writeFile` in `merge.ts` to resolve paths to absolute paths and check if directory exists before creating
  2. Created `writeTextFile` helper in `scaffold.ts` to properly handle text file writes with backup support
  3. Updated `updateIgnoreFiles` to use `writeTextFile` instead of `mergeFile` for `.gitignore` and `.cursorignore`
- **Prevention**: Always resolve paths to absolute paths before directory operations, and use appropriate file writing functions for text vs structured data files
- **Status**: resolved
