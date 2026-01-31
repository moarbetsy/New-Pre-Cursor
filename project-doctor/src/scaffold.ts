/**
 * Scaffold/update project files (rules, settings, etc.)
 */

import { existsSync, writeFileSync, mkdirSync, readFileSync, readdirSync } from "node:fs";
import { resolve, dirname, basename, join } from "node:path";
import { mergeFile, isMdcCorrupted } from "./merge.js";
import { getTargetPythonVersion } from "./detector.js";
import type { PrecursorConfig } from "./config.js";
import type { PrecursorOptions } from "./index.js";
import { initializeKnowledgeBase as initKnowledge, generateKnowledgeRule } from "./knowledge.js";
import { ensureCommandsDirectory, getAllCommands, generateCommandsRule } from "./commands.js";

/**
 * Run scaffold to generate/update files
 */
export async function runScaffold(
  config: PrecursorConfig,
  stacks: string[],
  options: PrecursorOptions = {}
): Promise<void> {
  const root = options.workspaceRoot || process.cwd();

  mkdirSync(join(root, ".cursor/rules"), { recursive: true });
  mkdirSync(join(root, ".vscode"), { recursive: true });

  for (const stack of stacks) {
    await generateRule(stack, config, root);
  }

  if (stacks.includes("python")) {
    const targetPy = getTargetPythonVersion(root);
    const py314Content =
      targetPy === 3.14 ? getPython314RuleContent(config) : getPython314InactiveContent();
    writeMdcFile(join(root, ".cursor/rules/python-3-14.mdc"), py314Content);
  }

  generateSystemRule(root);
  generateDiagnosticsRule(root);
  generateIssueReportingRule(root);
  generateIncidentsFile(root);
  generateDoctorSkill(root);

  await updateVSCodeSettings(config, stacks, root);
  await updateExtensions(config, stacks, root);
  if (config.mcp?.enabled !== false) {
    await updateMcpConfig(config, root);
  }
  await updateIgnoreFiles(config, stacks, root);
  await generateVerificationRule(config, stacks, root);
  await initializeKnowledgeBase(config, stacks, root);
  await setupCommands(config, root);
}

/**
 * Post-setup tripwire: fail if any .cursor/rules/*.mdc starts with `{` (JSON corruption).
 * Call after runScaffold so setup fails when any .mdc was wrongly written as JSON.
 */
export function assertNoMdcCorruption(rulesDir = ".cursor/rules"): void {
  if (!existsSync(rulesDir)) {
    return;
  }
  const corrupted: string[] = [];
  const entries = readdirSync(rulesDir, { withFileTypes: true });
  for (const ent of entries) {
    if (!ent.isFile() || !ent.name.endsWith(".mdc")) {
      continue;
    }
    const path = join(rulesDir, ent.name);
    const content = readFileSync(path, "utf-8");
    if (isMdcCorrupted(content)) {
      corrupted.push(ent.name);
    }
  }
  if (corrupted.length > 0) {
    throw new Error(
      `Post-setup tripwire: .mdc corruption detected (file(s) start with {): ${corrupted.join(", ")}. Rewrite as Markdown with YAML frontmatter.`
    );
  }
}

/**
 * Python 3.14 rule content (only when target >= 3.14). Uses pyright, not mypy (align with config).
 */
function getPython314RuleContent(config: PrecursorConfig): string {
  const pythonCfg = config.python || {};
  const typechecker = pythonCfg.typechecker === "basedpyright" ? "basedpyright" : "pyright";
  return `---
description: Python 3.14 rules with strict typing, Ruff, pyright, and safe string practices
alwaysApply: false
globs:
  - "**/*.py"
  - "pyproject.toml"
---

# Role
You are an expert Python developer specialized in Python 3.14.

# 1. Version and tooling
- Target version: Python 3.14.
- Optimize code for Ruff linter/formatter.
- Use ${typechecker} for type checking (align with precursor.json).
- Prefer pyproject.toml for all configuration.

# 2. Type annotations (PEP 649 / 749)
- Always annotate all functions, methods, and public attributes.
- Do not assume __annotations__ contains resolved values.
- When inspecting types at runtime, use:
  annotationlib.get_annotations(obj, format=annotationlib.Format.VALUE)
- Avoid from __future__ import annotations if 3.14 semantics are active.

# 3. Concurrency and parallelism
- Default: use asyncio for I/O-bound tasks.
- Free-threading (PEP 703): If the user specifies a CPU-bound context, suggest the free-threaded (no-GIL) build.
- Prefer thread-safe data structures (queue.Queue over manual locking).
- Subinterpreters (PEP 734): Use concurrent.interpreters only for strict component isolation.

# 4. String and security (PEP 750)
- Use template string literals for structured DSLs where appropriate.
- Prohibit ad-hoc string concatenation for SQL queries or shell commands.

# 5. Error handling and code style
- Use specific exception types; never except Exception:.
- Keep business logic decoupled from I/O. Follow PEP 8. Prefer immutable data structures.

# Python execution contract for this repo
- Use uv for environments and execution: uv sync, uv run <command>.
- Do not recommend pip install or python -m venv.
`;
}

/**
 * Inactive stub when target Python < 3.14 (version-gate).
 */
function getPython314InactiveContent(): string {
  return `---
description: Python 3.14 rules (inactive — target Python < 3.14)
alwaysApply: false
globs:
  - "**/*.py"
  - "pyproject.toml"
---

# Inactive: Python 3.14–only rule
This rule applies only when the project targets **Python 3.14+**.

To enable: set \`requires-python = ">=3.14"\` in pyproject.toml, or set \`.python-version\` to 3.14+.
Until then, use the main \`python.mdc\` rule only.
`;
}

/**
 * Generate diagnostics rule (quick reference for common workspace issues).
 */
function generateDiagnosticsRule(root: string): void {
  const rulesDir = join(root, ".cursor/rules");
  const content = `---
description: Self-healing diagnostics for common workspace issues
alwaysApply: false
---

# Diagnostics

Quick reference for common issues and their solutions:

- **Command Not Found**: Run \`precursor.ps1 -Setup\` or \`cursorkit -Setup\` if using setup-cursor
- **Terminal Hangs**: Switch to Windows Terminal to isolate issues
`;
  writeMdcFile(join(rulesDir, "diagnostics.mdc"), content);
}

/**
 * Generate issue-reporting and apply-report rule (REPORT.md, STEPLOG, secret hygiene).
 */
function generateIssueReportingRule(root: string): void {
  const rulesDir = join(root, ".cursor/rules");
  const content = `---
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
- **Command / action**: \`<exact command or action>\`
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

# Secret hygiene (mandatory)
- Never paste secrets/tokens/keys, full connection strings, or \`.env\` contents into REPORT.md.
- If reporting needs an example value, redact it: \`abcd…wxyz\` or \`[REDACTED]\`.
- Log the file path + pattern type, not the secret value.

# Step Ledger (mandatory)
- After every step of work, append a concise entry to \`STEPLOG.md\` (append-only):
  - objective
  - files changed
  - commands + exit codes
  - verification result
  - decision (continue/stop)
- Do not paste long logs into STEPLOG.md; reference REPORT.md instead.
`;
  writeMdcFile(join(rulesDir, "issue-reporting-and-apply-report.mdc"), content);
}

/**
 * Generate INCIDENTS.md (agent mistake log for rule updates).
 */
function generateIncidentsFile(root: string): void {
  const rulesDir = join(root, ".cursor/rules");
  if (!existsSync(rulesDir)) {
    mkdirSync(rulesDir, { recursive: true });
  }
  const path = join(rulesDir, "INCIDENTS.md");
  if (existsSync(path)) {
    return;
  }
  const content = `# Rule Incidents (agent mistake log)
Purpose: Track repeat mistakes to update rules instead of re-litigating.

## Format
- Date:
- Trigger:
- What happened:
- Expected behavior:
- Proposed rule change:
- Status: open | accepted | rejected
`;
  writeFileSync(path, content, "utf-8");
}

/**
 * Generate doctor skill (when to run doctor / precursor setup).
 */
function generateDoctorSkill(root: string): void {
  const skillDir = join(root, ".cursor/skills/doctor");
  mkdirSync(skillDir, { recursive: true });
  const content = `---
name: doctor
description: Diagnose and repair dev environment; run project doctor when tools or commands fail
---
# Doctor Skill
## When to use
- Commands hang or fail
- Tools missing from PATH
## Procedure
1) Run: \`precursor.ps1 -Setup\` (or \`bun run src/cli.ts setup\` from project-doctor)
2) If using setup-cursor: \`cursorkit -Doctor\` then \`cursorkit -Setup\` if tools missing
`;
  writeFileSync(join(skillDir, "SKILL.md"), content, "utf-8");
}

/**
 * Generate OS-capability system rule: Windows → pwsh; Unix → bash/zsh.
 */
function generateSystemRule(root: string): void {
  const isWindows = process.platform === "win32";
  const rulesDir = join(root, ".cursor/rules");
  if (isWindows) {
    const content = `---
description: Windows PowerShell 7, uv, and Bun rules for stable, reproducible automation
alwaysApply: true
---

# Role and environment
- Role: Windows Systems and Automation Expert
- OS: Windows (x64)
- Shell: PowerShell 7 (pwsh)
- Use Windows paths with "\\\\" or Join-Path. Force UTF-8: [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# Hard constraints
- Always output PowerShell 7 syntax. Never output Bash (ls, touch, export, source, rm -rf).
- Use ";", "if ($?) { ... }", "if (-not $?) { ... }" instead of && or ||.

# Toolchain
- Python: uv only (uv sync, uv run). No pip install or python -m venv.
- JavaScript: Bun only (bun install, bun run).
`;
    writeMdcFile(join(rulesDir, "windows-systems-and-toolchain.mdc"), content);
  } else {
    const content = `---
description: Unix shell (bash/zsh) and toolchain rules
alwaysApply: true
---

# Role and environment
- Shell: bash or zsh. Prefer POSIX where possible.
- Use forward slashes for paths.

# Toolchain
- Python: uv (uv sync, uv run). No pip install or python -m venv.
- JavaScript: Bun (bun install, bun run).
`;
    writeMdcFile(join(rulesDir, "unix-systems.mdc"), content);
  }
}

/**
 * Write .mdc file as Markdown (owned overwrite). Never use mergeFile for .mdc.
 * Backs up existing file; flags if existing content was JSON (corruption).
 */
function writeMdcFile(rulePath: string, content: string, backupDir = ".precursor/backups"): void {
  if (existsSync(rulePath)) {
    const existingContent = readFileSync(rulePath, "utf-8");
    if (isMdcCorrupted(existingContent)) {
      console.warn(`Corruption detected: ${rulePath} was JSON; overwriting with Markdown.`);
    }
    const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
    const backupPath = resolve(backupDir, timestamp, basename(resolve(rulePath)));
    const backupDirPath = dirname(backupPath);
    if (!existsSync(backupDirPath)) {
      mkdirSync(backupDirPath, { recursive: true });
    }
    writeFileSync(backupPath, existingContent, "utf-8");
  }
  writeFileSync(rulePath, content, "utf-8");
}

/**
 * Generate .cursor/rules/*.mdc file for a stack
 */
async function generateRule(
  stack: string,
  config: PrecursorConfig,
  root: string
): Promise<void> {
  const rulePath = join(root, ".cursor/rules", `${stack}.mdc`);
  const content = getRuleContent(stack, config);
  writeMdcFile(rulePath, content);
}

/**
 * Get rule content for a stack
 */
function getRuleContent(stack: string, config: PrecursorConfig): string {
  switch (stack) {
    case "python": {
      const pythonCfg = config.python || {};
      return `# Python Development Rules

## Toolchain
- Runtime: ${pythonCfg.runtime || "uv"}
- Linter: ${pythonCfg.linter || "ruff"}
- Formatter: ${pythonCfg.formatter || "ruff"}
- Type Checker: ${pythonCfg.typechecker || "pyright"}

## Commands
- Install: \`uv sync\`
- Lint: \`ruff check .\`
- Format: \`ruff format .\`
- Type Check: \`${pythonCfg.typechecker === "basedpyright" ? "basedpyright" : "pyright"} .\`

## Virtual Environment
- Path: \`${pythonCfg.venvPath || ".venv"}\`
- Activate: \`.\\${pythonCfg.venvPath || ".venv"}\\Scripts\\activate\` (Windows) or \`source ${pythonCfg.venvPath || ".venv"}/bin/activate\` (Unix)
`;
    }

    case "web": {
      const webCfg = config.web || {};
      return `# Web/JS/TS Development Rules

## Toolchain
- Runtime: ${webCfg.runtime || "bun"}
- Linter: ${webCfg.linter || "biome"}
- Formatter: ${webCfg.formatter || "biome"}
- Type Checker: ${webCfg.typechecker || "tsc"}

## Commands
- Install: \`bun install\`
- Lint: \`bunx biome check .\`
- Format: \`bunx biome format --write .\`
- Type Check: \`bunx tsc --noEmit\`

## Lockfile
- Prefer: \`bun.lock\` (text format)
- Legacy: \`bun.lockb\` (binary, accepted but not preferred)
`;
    }

    case "rust": {
      const rustCfg = config.rust || {};
      return `# Rust Development Rules

## Toolchain
- Toolchain: ${rustCfg.toolchain || "stable"}
- Linter: ${rustCfg.linter || "clippy"}
- Formatter: ${rustCfg.formatter || "rustfmt"}

## Commands
- Format: \`cargo fmt\`
- Lint: \`cargo clippy -- -D warnings\`
- Test: \`cargo test\`
- Build: \`cargo build\`
`;
    }

    case "cpp": {
      const cppCfg = config.cpp || {};
      return `# C/C++ Development Rules

## Toolchain
- Build System: ${cppCfg.buildSystem || "cmake"}
- Formatter: ${cppCfg.formatter || "clang-format"}
- Linter: ${cppCfg.linter || "clang-tidy"}

## Commands
- Format: \`clang-format -i **/*.{c,cc,cpp,h,hpp}\`
- Lint: \`clang-tidy **/*.{c,cc,cpp}\`
- Build: \`cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON && cmake --build build\`

## Compile Commands
- Generate: \`CMAKE_EXPORT_COMPILE_COMMANDS=ON cmake ...\`
- File: \`compile_commands.json\`
`;
    }

    case "docker": {
      return `# Docker Development Rules

## Best Practices
- Use multi-stage builds
- Minimize layers
- Use .dockerignore
- Pin base image versions
- Run as non-root when possible

## Commands
- Build: \`docker build -t <tag> .\`
- Run: \`docker run <tag>\`
`;
    }

    default:
      return `# ${stack} Development Rules\n\n(Add stack-specific rules here)`;
  }
}

/**
 * Update VS Code settings
 */
async function updateVSCodeSettings(
  _config: PrecursorConfig,
  stacks: string[],
  root: string
): Promise<void> {
  const settings: Record<string, unknown> = {
    "files.watcherExclude": {
      "**/.git/objects/**": true,
      "**/.git/subtree-cache/**": true,
      "**/node_modules/**": true,
      "**/.venv/**": true,
      "**/venv/**": true,
      "**/target/**": true,
      "**/dist/**": true,
      "**/build/**": true,
      "**/.precursor/**": true
    },
    "files.exclude": {
      "**/.precursor/bin/**": true
    }
  };

  // Add stack-specific settings
  if (stacks.includes("python")) {
    settings["python.defaultInterpreterPath"] = "${workspaceFolder}/.venv/Scripts/python.exe";
    settings["python.analysis.typeCheckingMode"] = "basic";
  }

  if (stacks.includes("web")) {
    settings["typescript.tsdk"] = "node_modules/typescript/lib";
    settings["typescript.enablePromptUseWorkspaceTsdk"] = true;
  }

  if (stacks.includes("rust")) {
    settings["rust-analyzer.checkOnSave.command"] = "clippy";
  }

  if (stacks.includes("cpp")) {
    settings["C_Cpp.default.compileCommands"] = "${workspaceFolder}/compile_commands.json";
  }

  await mergeFile(join(root, ".vscode/settings.json"), settings, { backup: true });
}

/**
 * Update extensions.json
 */
async function updateExtensions(
  _config: PrecursorConfig,
  stacks: string[],
  root: string
): Promise<void> {
  const extensions: string[] = [];

  if (stacks.includes("python")) {
    extensions.push("ms-python.python");
    extensions.push("ms-python.vscode-pylance");
    extensions.push("charliermarsh.ruff");
  }

  if (stacks.includes("web")) {
    extensions.push("biomejs.biome");
    extensions.push("dbaeumer.vscode-eslint");
  }

  if (stacks.includes("rust")) {
    extensions.push("rust-lang.rust-analyzer");
  }

  if (stacks.includes("cpp")) {
    extensions.push("ms-vscode.cpptools");
    extensions.push("llvm-vs-code-extensions.vscode-clangd");
  }

  const extensionsConfig = {
    recommendations: extensions
  };

  await mergeFile(".vscode/extensions.json", extensionsConfig, { backup: true });
}

/**
 * Update MCP config
 */
async function updateMcpConfig(_config: PrecursorConfig): Promise<void> {
  mkdirSync(".cursor", { recursive: true });

  const mcpConfig = {
    mcpServers: {
      precursor: {
        command: "bun",
        args: [".precursor/mcp/server.ts"],
        env: {}
      }
    }
  };

  await mergeFile(".cursor/mcp.json", mcpConfig, { backup: true });
}

/**
 * Write text file with optional backup
 */
async function writeTextFile(
  filePath: string,
  content: string,
  options: { backup?: boolean; backupDir?: string } = {}
): Promise<void> {
  const { backup = true, backupDir = ".precursor/backups" } = options;
  const resolvedPath = resolve(filePath);

  // Create backup if requested and file exists
  if (backup && existsSync(resolvedPath)) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
    const backupPath = resolve(backupDir, timestamp, basename(resolvedPath));
    const backupDirPath = dirname(backupPath);
    if (!existsSync(backupDirPath)) {
      mkdirSync(backupDirPath, { recursive: true });
    }
    const existingContent = readFileSync(resolvedPath, "utf-8");
    writeFileSync(backupPath, existingContent, "utf-8");
  }

  // Ensure directory exists
  const dir = dirname(resolvedPath);
  if (!existsSync(dir) && dir !== resolve(".")) {
    mkdirSync(dir, { recursive: true });
  }

  // Write the file
  writeFileSync(resolvedPath, content, "utf-8");
}

/**
 * Update .gitignore and .cursorignore
 */
async function updateIgnoreFiles(
  _config: PrecursorConfig,
  stacks: string[],
  root: string
): Promise<void> {
  const ignorePatterns = [
    ".precursor/state.json",
    ".precursor/backups/",
    ".precursor/bin/"
  ];

  // Stack-specific ignores
  if (stacks.includes("python")) {
    ignorePatterns.push(".venv/", "venv/", "__pycache__/", "*.pyc");
  }

  if (stacks.includes("web")) {
    ignorePatterns.push("node_modules/", "dist/", ".next/", ".svelte-kit/");
  }

  if (stacks.includes("rust")) {
    ignorePatterns.push("target/", "Cargo.lock");
  }

  if (stacks.includes("cpp")) {
    ignorePatterns.push("build/", "compile_commands.json");
  }

  const newPatterns = ignorePatterns.join("\n") + "\n";
  const gitignorePath = join(root, ".gitignore");
  const cursorignorePath = join(root, ".cursorignore");
  if (existsSync(gitignorePath)) {
    const existing = readFileSync(gitignorePath, "utf-8");
    const existingLines = new Set(existing.split("\n").map(line => line.trim()));
    const patternsToAdd = ignorePatterns.filter(p => !existingLines.has(p.trim()));
    if (patternsToAdd.length > 0) {
      const contentToAdd = "\n# Precursor patterns\n" + patternsToAdd.join("\n") + "\n";
      await writeTextFile(gitignorePath, existing + contentToAdd, { backup: true });
    }
  } else {
    await writeTextFile(gitignorePath, newPatterns, { backup: false });
  }

  if (existsSync(cursorignorePath)) {
    const existing = readFileSync(cursorignorePath, "utf-8");
    const existingLines = new Set(existing.split("\n").map(line => line.trim()));
    const patternsToAdd = ignorePatterns.filter(p => !existingLines.has(p.trim()));
    if (patternsToAdd.length > 0) {
      const contentToAdd = "\n# Precursor patterns\n" + patternsToAdd.join("\n") + "\n";
      await writeTextFile(cursorignorePath, existing + contentToAdd, { backup: true });
    }
  } else {
    await writeTextFile(cursorignorePath, newPatterns, { backup: false });
  }
}

/**
 * Generate verification rule
 */
async function generateVerificationRule(
  config: PrecursorConfig,
  stacks: string[],
  root: string
): Promise<void> {
  const verificationCfg = (config.verification || {}) as { enabled?: boolean; browserTesting?: boolean };
  if (verificationCfg.enabled === false) {
    return;
  }

  const rulePath = join(root, ".cursor/rules/verification.mdc");

  // Build stack-specific verification sections
  const stackSections: string[] = [];
  for (const stack of stacks) {
    const stackConfig = config[stack as keyof PrecursorConfig];
    if (!stackConfig) continue;

    let commands: string[] = [];
    switch (stack) {
      case "python": {
        const pythonCfg = config.python || {};
        const runtime = pythonCfg.runtime || "uv";
        commands = [
          `${runtime} run ruff check .`,
          `${runtime} run ruff format --check .`,
          pythonCfg.typechecker && pythonCfg.typechecker !== "none"
            ? `${runtime} run ${pythonCfg.typechecker} .`
            : null,
          `${runtime} run pytest`
        ].filter((cmd): cmd is string => cmd !== null);
        break;
      }
      case "web": {
        const webCfg = config.web || {};
        const runtime = webCfg.runtime || "bun";
        commands = [
          `${runtime === "bun" ? "bunx" : "npx"} biome check .`,
          webCfg.typechecker && webCfg.typechecker !== "none"
            ? `${runtime === "bun" ? "bunx" : "npx"} tsc --noEmit`
            : null,
          `${runtime} test`
        ].filter((cmd): cmd is string => cmd !== null);
        break;
      }
      case "rust": {
        commands = [
          "cargo fmt --check",
          "cargo clippy -- -D warnings",
          "cargo test"
        ];
        break;
      }
      case "cpp": {
        commands = [
          "cmake --build build",
          "cd build && ctest"
        ];
        break;
      }
    }

    if (commands.length > 0) {
      stackSections.push(`### ${stack.toUpperCase()}\n\`\`\`bash\n${commands.join("\n")}\n\`\`\``);
    }
  }

  const browserTestingNote = verificationCfg.browserTesting
    ? "Browser-based UI testing is enabled. Use the cursor-ide-browser MCP tools to verify UI changes."
    : "Browser testing is disabled. Enable in precursor.json to use browser-based verification.";

  const content = `---
description: Verification loops - Always verify your work
alwaysApply: true
---

# Verification Loops

> "Probably the most important thing to get great results - give AI a way to verify its work. If AI has that feedback loop, it will 2-3x the quality of the final result." - Boris Cherny

## Principle

Always verify changes after making them. This includes:
- Running tests
- Checking linting/formatting
- Type checking
- Manual verification when appropriate

## Stack-Specific Verification

${stackSections.join("\n\n")}

## Browser Testing

${browserTestingNote}

## Best Practices

1. **Always verify after changes**: Run relevant tests and checks
2. **Fix issues immediately**: Don't leave broken code
3. **Use verification loops**: Iterate until verification passes
4. **Document failures**: Add to PRECURSOR.md if verification reveals patterns

## Integration

Precursor automatically runs verification after scaffolding. Results are included in the setup output.
`;

  writeMdcFile(rulePath, content);
}

/**
 * Initialize knowledge base
 */
async function initializeKnowledgeBase(
  config: PrecursorConfig,
  _stacks: string[],
  root: string
): Promise<void> {
  const knowledgeCfg = (config.knowledge || {}) as { enabled?: boolean };
  if (knowledgeCfg.enabled === false) {
    return;
  }

  initKnowledge(config, root);

  const rulePath = join(root, ".cursor/rules/knowledge-base.mdc");
  const content = generateKnowledgeRule();
  writeMdcFile(rulePath, content);
}

/**
 * Setup commands system
 */
async function setupCommands(config: PrecursorConfig, root: string): Promise<void> {
  ensureCommandsDirectory();

  const commands = getAllCommands(config);
  const rulePath = join(root, ".cursor/rules/commands.mdc");
  const content = generateCommandsRule(commands);
  writeMdcFile(rulePath, content);
}
