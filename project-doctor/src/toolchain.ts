/**
 * Tool resolution and installation waterfall
 */

import { existsSync } from "node:fs";
import { join } from "node:path";
import { execSync } from "node:child_process";
import type { PrecursorConfig } from "./config.js";

export interface ToolResult {
  found: boolean;
  version?: string;
  path?: string;
  source?: "system" | "package-manager" | "portable";
  critical?: boolean;
  error?: string;
}

export interface PrecursorOptions {
  offline?: boolean;
  strict?: boolean;
}

/**
 * Resolve tool location and version
 */
export async function resolveTool(
  toolId: string,
  config: PrecursorConfig,
  options: PrecursorOptions = {}
): Promise<ToolResult> {
  // Check system PATH first
  const systemResult = await checkSystemPath(toolId);
  if (systemResult.found) {
    return { ...systemResult, source: "system" };
  }

  // Check package manager (if not offline)
  if (!options.offline) {
    const pmResult = await checkPackageManager(toolId, config);
    if (pmResult.found) {
      return { ...pmResult, source: "package-manager" };
    }

    // Check portable cache
    const portableResult = await checkPortable(toolId);
    if (portableResult.found) {
      return { ...portableResult, source: "portable" };
    }
  } else {
    // In offline mode, check portable cache only
    const portableResult = await checkPortable(toolId);
    if (portableResult.found) {
      return { ...portableResult, source: "portable" };
    }
  }

  // Not found
  const toolConfig = getToolConfig(toolId, config);
  return {
    found: false,
    critical: toolConfig?.critical ?? isCriticalTool(toolId)
  };
}

/**
 * Install tool using waterfall strategy
 */
export async function installTool(
  toolId: string,
  config: PrecursorConfig,
  options: PrecursorOptions = {}
): Promise<ToolResult> {
  if (options.offline) {
    throw new Error(`Cannot install ${toolId} in offline mode`);
  }

  const toolConfig = getToolConfig(toolId, config);
  const installSource = toolConfig?.installSource ?? "auto";

  // Try system package manager first (if supported)
  if (installSource === "auto" || installSource === "package-manager") {
    try {
      const result = await installViaPackageManager(toolId, config);
      if (result.found) {
        return result;
      }
    } catch (error) {
      // Continue to next method
    }
  }

  // Try portable installation
  if (installSource === "auto" || installSource === "portable") {
    try {
      const result = await installPortable(toolId, config);
      if (result.found) {
        return result;
      }
    } catch (error) {
      // Continue
    }
  }

  throw new Error(`Failed to install ${toolId} via any method`);
}

/**
 * Check if tool exists in system PATH
 */
async function checkSystemPath(toolId: string): Promise<ToolResult> {
  try {
    // Try to run tool with --version or -v
    const output = execSync(`${toolId} --version`, {
      encoding: "utf-8",
      stdio: ["ignore", "pipe", "ignore"],
      timeout: 5000
    });

    const version = extractVersion(output);
    return {
      found: true,
      version,
      path: "PATH"
    };
  } catch {
    // Not found
    return { found: false };
  }
}

/**
 * Check package manager for tool
 */
async function checkPackageManager(
  toolId: string,
  _config: PrecursorConfig
): Promise<ToolResult> {
  // Platform-specific package managers
  const platform = process.platform;

  if (platform === "win32") {
    // Try winget
    try {
      const output = execSync(`winget list --id ${toolId}`, {
        encoding: "utf-8",
        stdio: ["ignore", "pipe", "ignore"],
        timeout: 10000
      });
      if (output.includes(toolId)) {
        return { found: true, path: "winget" };
      }
    } catch {
      // Not installed via winget
    }
  }

  // Could add brew, apt, dnf, pacman checks here
  return { found: false };
}

/**
 * Check portable binary cache
 */
async function checkPortable(toolId: string): Promise<ToolResult> {
  const portableDir = join(".precursor", "bin", toolId);
  if (!existsSync(portableDir)) {
    return { found: false };
  }

  // Look for latest version
  try {
    const output = execSync(`ls "${portableDir}"`, {
      encoding: "utf-8",
      shell: true
    } as any);
    const versions = (output as string)
      .trim()
      .split("\n")
      .filter(v => v);

    if (versions.length > 0) {
      const latest = versions.sort().reverse()[0];
      const toolPath = join(portableDir, latest, getToolBinaryName(toolId));

      if (existsSync(toolPath)) {
        return {
          found: true,
          version: latest,
          path: toolPath
        };
      }
    }
  } catch {
    // Error reading directory
  }

  return { found: false };
}

/**
 * Install via system package manager
 */
async function installViaPackageManager(
  toolId: string,
  _config: PrecursorConfig
): Promise<ToolResult> {
  const platform = process.platform;

  if (platform === "win32") {
    try {
      execSync(`winget install --id ${toolId} --silent`, {
        stdio: "inherit",
        timeout: 300000
      });
      // Verify installation
      return await checkSystemPath(toolId);
    } catch (error) {
      throw new Error(`winget install failed: ${error}`);
    }
  }

  throw new Error(`Package manager installation not supported on ${platform}`);
}

/**
 * Install portable binary
 */
async function installPortable(
  toolId: string,
  _config: PrecursorConfig
): Promise<ToolResult> {
  // This would download and extract the tool
  // For now, return not found (implementation would require tool-specific download logic)
  throw new Error(`Portable installation not yet implemented for ${toolId}`);
}

/**
 * Get tool config from global config
 */
function getToolConfig(
  toolId: string,
  config: PrecursorConfig
): { critical?: boolean; installSource?: string; version?: string } | null {
  return (config.tools?.[toolId] as { critical?: boolean; installSource?: string; version?: string }) ?? null;
}

/**
 * Check if tool is critical by default
 */
function isCriticalTool(toolId: string): boolean {
  const criticalTools = ["uv", "bun", "cargo", "rustc", "python"];
  return criticalTools.includes(toolId);
}

/**
 * Extract version from command output
 */
function extractVersion(output: string): string {
  // Try to extract semantic version
  const versionMatch = output.match(/(\d+\.\d+\.\d+)/);
  if (versionMatch) {
    return versionMatch[1];
  }

  // Fallback: return first line
  return output.split("\n")[0].trim();
}

/**
 * Get binary name for tool (platform-specific)
 */
function getToolBinaryName(toolId: string): string {
  const platform = process.platform;
  const extension = platform === "win32" ? ".exe" : "";

  // Some tools have different binary names
  const binaryMap: Record<string, string> = {
    "clang-format": "clang-format",
    "clang-tidy": "clang-tidy"
  };

  return binaryMap[toolId] ?? toolId + extension;
}
