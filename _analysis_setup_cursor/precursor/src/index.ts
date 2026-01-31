#!/usr/bin/env bun

/**
 * Precursor - Config-driven project doctor + scaffolder for Cursor
 * Main entry point for the TypeScript core
 */

export * from "./config.js";
export * from "./merge.js";
export * from "./state.js";
export * from "./detector.js";
export * from "./toolchain.js";
export * from "./doctor.js";
export * from "./scaffold.js";
export * from "./ci.js";
export * from "./secrets.js";
export * from "./backup.js";
export * from "./system.js";
export * from "./report.js";
export * from "./verification.js";
export * from "./hooks.js";
export * from "./knowledge.js";
export * from "./commands.js";

import type { PrecursorConfig } from "./config.js";
import { loadConfig, validateConfig } from "./config.js";
import { detectStacks } from "./detector.js";
import { runDoctor } from "./doctor.js";
import { runScaffold } from "./scaffold.js";
import { generateWorkflows } from "./ci.js";
import { scanSecrets } from "./secrets.js";
import { ensureBackup, restoreBackup } from "./backup.js";
import { updateState, resetState } from "./state.js";
import { resolveTool, installTool } from "./toolchain.js";
import { runVerification } from "./verification.js";
import { runPostScaffoldHooks } from "./hooks.js";

export interface PrecursorOptions {
  configPath?: string;
  strict?: boolean;
  offline?: boolean;
  json?: boolean;
  noColor?: boolean;
}

export interface PrecursorResult {
  success: boolean;
  message?: string;
  data?: unknown;
  errors?: string[];
  warnings?: string[];
}

/**
 * Main setup function - idempotent bootstrap
 */
export async function setup(options: PrecursorOptions = {}): Promise<PrecursorResult> {
  try {
    const config = await loadConfig(options.configPath);
    await validateConfig(config);

    // Ensure backup before any writes
    if (config.backup?.enabled !== false) {
      await ensureBackup(config);
    }

    // Detect stacks
    const stacks = await detectStacks(config);
    
    // Resolve and install tools
    const toolResults = await resolveAndInstallTools(config, stacks, options);

    // Generate/update files
    await runScaffold(config, stacks, options);

    // Run post-scaffold hooks (formatting, etc.)
    await runPostScaffoldHooks(config, stacks, options);

    // Run verification loops
    const verificationReport = await runVerification(config, stacks, options);
    const verificationCfg = (config.verification || {}) as { failOnError?: boolean };
    if (!verificationReport.success && verificationCfg.failOnError === true) {
      return {
        success: false,
        message: "Verification failed",
        data: verificationReport,
        errors: verificationReport.errors,
        warnings: verificationReport.warnings
      };
    }

    // Generate CI workflows
    if (config.ci?.enabled !== false) {
      await generateWorkflows(config, stacks, options);
    }

    // Scan for secrets
    if (config.secrets?.enabled !== false) {
      const secretResults = await scanSecrets(config);
      if (secretResults.found.length > 0) {
        return {
          success: false,
          message: "Secrets detected in codebase",
          data: secretResults,
          warnings: secretResults.found.map(s => `Secret found: ${s.path}`)
        };
      }
    }

    // Update state
    await updateState(config, stacks);

    return {
      success: true,
      message: "Setup completed successfully",
      data: { stacks, tools: toolResults }
    };
  } catch (error) {
    return {
      success: false,
      message: error instanceof Error ? error.message : String(error),
      errors: [error instanceof Error ? error.stack || error.message : String(error)]
    };
  }
}

/**
 * Scan-only doctor mode
 */
export async function scan(options: PrecursorOptions = {}): Promise<PrecursorResult> {
  try {
    const config = await loadConfig(options.configPath);
    await validateConfig(config);

    const stacks = await detectStacks(config);
    const doctorReport = await runDoctor(config, stacks, options);

    return {
      success: true,
      message: "Scan completed",
      data: doctorReport
    };
  } catch (error) {
    return {
      success: false,
      message: error instanceof Error ? error.message : String(error),
      errors: [error instanceof Error ? error.stack || error.message : String(error)]
    };
  }
}

/**
 * Rollback to latest backup
 */
export async function rollback(options: PrecursorOptions = {}): Promise<PrecursorResult> {
  try {
    const config = await loadConfig(options.configPath);
    const result = await restoreBackup(config);
    
    return {
      success: result.success,
      message: result.message,
      data: result
    };
  } catch (error) {
    return {
      success: false,
      message: error instanceof Error ? error.message : String(error),
      errors: [error instanceof Error ? error.stack || error.message : String(error)]
    };
  }
}

/**
 * Reset state cache
 */
export async function reset(_options: PrecursorOptions = {}): Promise<PrecursorResult> {
  try {
    await resetState();
    return {
      success: true,
      message: "State cache reset"
    };
  } catch (error) {
    return {
      success: false,
      message: error instanceof Error ? error.message : String(error),
      errors: [error instanceof Error ? error.stack || error.message : String(error)]
    };
  }
}

async function resolveAndInstallTools(
  config: PrecursorConfig,
  stacks: string[],
  options: PrecursorOptions
): Promise<Record<string, unknown>> {
  const results: Record<string, unknown> = {};

  for (const stack of stacks) {
    const stackConfig = config[stack as keyof PrecursorConfig];
    if (!stackConfig || (stackConfig as { enabled?: boolean }).enabled === false) {
      continue;
    }

    // Resolve tools for this stack
    const toolIds = getToolIdsForStack(stack, stackConfig);
    
    for (const toolId of toolIds) {
      try {
        const tool = await resolveTool(toolId, config, options);
        if (tool && !tool.found && !options.offline) {
          if (tool.critical) {
            throw new Error(`Critical tool ${toolId} not found`);
          }
          // Try to install
          await installTool(toolId, config, options);
        }
        results[toolId] = tool;
      } catch (error) {
        if (options.strict) {
          throw error;
        }
        results[toolId] = { error: error instanceof Error ? error.message : String(error) };
      }
    }
  }

  return results;
}

function getToolIdsForStack(_stack: string, stackConfig: unknown): string[] {
  const tools: string[] = [];
  const cfg = stackConfig as Record<string, unknown>;

  if (cfg.runtime) tools.push(String(cfg.runtime));
  if (cfg.linter) tools.push(String(cfg.linter));
  if (cfg.formatter) tools.push(String(cfg.formatter));
  if (cfg.typechecker && cfg.typechecker !== "none") {
    tools.push(String(cfg.typechecker));
  }

  return tools;
}
