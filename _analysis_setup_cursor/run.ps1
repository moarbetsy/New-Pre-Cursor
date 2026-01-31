param(
  [string]$PythonEntrypoint = ".\main.py",
  [string]$JsScript = "dev",
  [switch]$PreflightOnly,
  [switch]$ApplyCursorSettings,
  [switch]$Bootstrap,
  [switch]$Clean,
  [string]$NewProject,
  [string]$DestinationRoot = "$HOME\Desktop",
  [switch]$Doctor,
  [switch]$Setup,  # Winget-like comprehensive setup
  [switch]$InstallTools,  # Install UV, Bun, etc.
  [switch]$UpdatePython,  # Update Python and dependencies
  [switch]$FixIssues,  # Apply fixes from REPORT.md
  [switch]$ApplyAllSettings,  # Apply all IDE settings
  [switch]$SetupMCP  # Setup MCP servers
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# UTF-8 stable output (reduces weird encoding issues in logs/tools)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$OutputEncoding = [System.Text.UTF8Encoding]::new()

$scriptPath = $MyInvocation.MyCommand.Path
if ($null -eq $scriptPath) {
    # Fallback for when script was executed via iex (no file path)
    # Assume we're already in the project root directory
    $ProjectRoot = Get-Location
} else {
    $ProjectRoot = Split-Path -Parent $scriptPath
}
Set-Location $ProjectRoot

$LogsDir = Join-Path $ProjectRoot "logs"
New-Item -ItemType Directory -Force -Path $LogsDir | Out-Null
$RunId = Get-Date -Format "yyyyMMdd-HHmmss"
$LogFile = Join-Path $LogsDir "run-$RunId.log"

function Log([string]$msg) {
  $line = "[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $msg
  $line | Tee-Object -FilePath $LogFile -Append
}

function Import-Env {
    if (Test-Path ".env") {
        Log "Loading .env file..."
        Get-Content ".env" | ForEach-Object {
            # Parse KEY=VALUE, ignoring comments
            if ($_ -match "^[^#]*=.*") {
                $k, $v = $_.split('=', 2)
                [Environment]::SetEnvironmentVariable($k.Trim(), $v.Trim(), "Process")
            }
        }
    }
}

function New-VirtualEnvironment {
    param([string]$VenvPath = ".\.venv")

    Log "Checking/creating Python virtual environment..."

    # Check if venv already exists and is functional
    $pythonExe = Join-Path $VenvPath "Scripts\python.exe"
    if ((Test-Path $pythonExe)) {
        Log "Virtual environment already exists, validating..."

        try {
            $testOutput = & $pythonExe --version 2>&1
            Log "Existing virtual environment is functional: $testOutput"
            return # Exit early - venv is already good
        }
        catch {
            Log "WARNING: Existing virtual environment is corrupted, recreating..."
            Remove-Item -Path $VenvPath -Recurse -Force
        }
    }

    # Create new venv
    Log "Creating new virtual environment..."
    & uv venv $VenvPath
    if ($LASTEXITCODE -ne 0) {
        Log "ERROR: Failed to create virtual environment"
        throw "Virtual environment creation failed"
    }

    # VALIDATE the venv actually works
    if (-not (Test-Path $pythonExe)) {
        Log "ERROR: Virtual environment created but python.exe not found at: $pythonExe"
        throw "Virtual environment validation failed"
    }

    # Test that the python executable actually works
    try {
        $testOutput = & $pythonExe --version 2>&1
        Log "Virtual environment validated: $testOutput"
    }
    catch {
        Log "ERROR: Created virtual environment is not functional"
        throw "Virtual environment validation failed"
    }
}

function Install-PythonDependencies {
    param([string]$RequirementsFile = "requirements.txt")

    if (-not (Test-Path $RequirementsFile)) {
        Log "No requirements file found: $RequirementsFile"
        return
    }

    Log "Checking/installing Python dependencies from $RequirementsFile..."

    # Check if we can use uv sync (preferred for pyproject.toml + uv.lock)
    $pyprojectToml = "pyproject.toml"
    $uvLock = "uv.lock"

    if ((Test-Path $pyprojectToml) -and (Test-Path $uvLock)) {
        Log "Using uv sync (pyproject.toml + uv.lock detected)..."
        & uv sync
        if ($LASTEXITCODE -ne 0) {
            Log "ERROR: Failed to sync Python dependencies with uv (exit code: $LASTEXITCODE)"
            throw "Dependency sync failed"
        }
    } else {
        # Fallback to pip install
        Log "Installing Python dependencies with uv pip..."
        & uv pip install -r $RequirementsFile

        if ($LASTEXITCODE -ne 0) {
            Log "ERROR: Failed to install Python dependencies (exit code: $LASTEXITCODE)"
            throw "Dependency installation failed"
        }
    }

    Log "Python dependencies ready"
}

function Install-JavaScriptDependencies {
    if (-not (Test-Path "package.json")) {
        Log "No package.json found, skipping JS dependencies"
        return
    }

    # Check if node_modules exists and bun.lockb is up to date
    $nodeModulesExists = Test-Path "node_modules"
    $bunLockExists = Test-Path "bun.lockb"

    if ($nodeModulesExists) {
        Log "JavaScript dependencies appear to be installed (node_modules exists)"

        # For bun, check if lockfile is newer than package.json
        if ($bunLockExists) {
            $packageJsonTime = (Get-Item "package.json").LastWriteTime
            $bunLockTime = (Get-Item "bun.lockb").LastWriteTime

            if ($bunLockTime -gt $packageJsonTime) {
                Log "bun.lockb is up to date, skipping dependency installation"
                return
            }
        }
    }

    Log "Installing JavaScript dependencies..."
    & bun install
    if ($LASTEXITCODE -ne 0) {
        Log "ERROR: Failed to install JavaScript dependencies (exit code: $LASTEXITCODE)"
        throw "JS dependency installation failed"
    }

    Log "JavaScript dependencies installed successfully"
}

function Set-CursorSettings {
  Log "Checking/applying Cursor PowerShell settings..."
  $CursorSettingsPath = "$env:APPDATA\Cursor\User\settings.json"
  $SettingsTemplatePath = Join-Path $ProjectRoot "cursor-settings.json"

  # Check if template exists
  if (-not (Test-Path $SettingsTemplatePath)) {
    Log "ERROR: Settings template not found at: $SettingsTemplatePath"
    Write-Host "ERROR: Settings template not found at: $SettingsTemplatePath" -ForegroundColor Red
    return $false
  }

  # Read the template settings
  try {
    $TemplateSettings = Get-Content $SettingsTemplatePath -Raw | ConvertFrom-Json
  } catch {
    Log "ERROR: Failed to parse settings template: $($_.Exception.Message)"
    Write-Host "ERROR: Failed to parse settings template: $($_.Exception.Message)" -ForegroundColor Red
    return $false
  }

  # Check if Cursor settings file exists, create if not
  if (-not (Test-Path $CursorSettingsPath)) {
    Log "Creating new Cursor settings file..."
    $CurrentSettings = @{}
  } else {
    # Read current settings
    try {
      $CurrentSettings = Get-Content $CursorSettingsPath -Raw | ConvertFrom-Json

      # Check if settings are already applied
      $alreadyApplied = $true
      foreach ($Property in $TemplateSettings.PSObject.Properties) {
        $currentValue = $CurrentSettings.($Property.Name)
        if ($null -eq $currentValue -or ($currentValue -ne $Property.Value)) {
          $alreadyApplied = $false
          break
        }
      }

      if ($alreadyApplied) {
        Log "Cursor settings already applied, skipping..."
        Write-Host "Cursor settings already applied!" -ForegroundColor Green
        return $true
      }

      Log "Merging with existing Cursor settings..."
    } catch {
      Log "WARNING: Could not parse existing settings file. Creating backup and starting fresh."
      $BackupPath = "$CursorSettingsPath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
      Copy-Item $CursorSettingsPath $BackupPath
      Log "Backup created: $BackupPath"
      $CurrentSettings = @{}
    }
  }

  # Merge settings (template overrides current for PowerShell-specific settings)
  $MergedSettings = $CurrentSettings

  # Add/update all template settings
  foreach ($Property in $TemplateSettings.PSObject.Properties) {
    $MergedSettings | Add-Member -MemberType NoteProperty -Name $Property.Name -Value $Property.Value -Force
  }

  # Write back to settings file
  try {
    $MergedSettings | ConvertTo-Json -Depth 10 | Set-Content $CursorSettingsPath -Encoding UTF8
    Log "Cursor settings applied successfully!"
    Write-Host "Cursor settings applied successfully!" -ForegroundColor Green
    Write-Host "Settings file: $CursorSettingsPath" -ForegroundColor Gray
    Write-Host "" -ForegroundColor White
    Write-Host "IMPORTANT: Restart Cursor for all settings to take effect" -ForegroundColor Yellow
    Write-Host "" -ForegroundColor White
    Write-Host "Key settings applied:" -ForegroundColor Cyan
    Write-Host "  - PowerShell as default language" -ForegroundColor White
    Write-Host "  - ISE-like IntelliSense and formatting" -ForegroundColor White
    Write-Host "  - Terminal fixes for Cursor compatibility" -ForegroundColor White
    Write-Host "  - OTBS (One True Brace Style) formatting" -ForegroundColor White
    return $true
  } catch {
    Log "ERROR: Failed to write settings file: $($_.Exception.Message)"
    Write-Host "ERROR: Failed to write settings file: $($_.Exception.Message)" -ForegroundColor Red
    return $false
  }
}

function Set-IdeFileExclusions {
  param(
    [Parameter(Mandatory=$true)][string]$ProjectRoot,
    [string[]]$KeepVisible = @("src")
  )

  Log "Checking/setting IDE file exclusions to hide everything except: $($KeepVisible -join ', ')"

  # Ensure .vscode directory exists
  $VscodeDir = Join-Path $ProjectRoot ".vscode"
  if (-not (Test-Path $VscodeDir)) {
    New-Item -ItemType Directory -Path $VscodeDir -Force | Out-Null
  }

  # Path to settings file
  $SettingsPath = Join-Path $VscodeDir "settings.json"

  # Read existing settings or create new object
  if (Test-Path $SettingsPath) {
    try {
      $jsonContent = Get-Content $SettingsPath -Raw | ConvertFrom-Json
      # Convert PSCustomObject back to hashtable for easier property manipulation
      $Settings = @{}
      $jsonContent.PSObject.Properties | ForEach-Object {
        $Settings[$_.Name] = $_.Value
      }
    } catch {
      Log "WARNING: Could not parse existing settings.json, creating new one"
      $Settings = @{}
    }
  } else {
    $Settings = @{}
  }

  # Check if exclusions are already set correctly
  $currentExclusions = $Settings."files.exclude"
  if ($currentExclusions) {
    # Build what the exclusions should be
    $ExpectedExclusions = @{}
    Get-ChildItem -LiteralPath $ProjectRoot -Force -ErrorAction SilentlyContinue | ForEach-Object {
      if ($KeepVisible -notcontains $_.Name) {
        $RelativePath = $_.Name
        if ($_.PSIsContainer) {
          $ExpectedExclusions["$RelativePath/**"] = $true
          $ExpectedExclusions["$RelativePath"] = $true
        } else {
          $ExpectedExclusions[$RelativePath] = $true
        }
      }
    }
    $ExpectedExclusions["**/.git"] = $true
    $ExpectedExclusions["**/.git/**"] = $true
    $ExpectedExclusions["**/.DS_Store"] = $true

    # Compare current vs expected
    $exclusionsMatch = $true
    if ($currentExclusions.Count -ne $ExpectedExclusions.Count) {
      $exclusionsMatch = $false
    } else {
      foreach ($key in $ExpectedExclusions.Keys) {
        if (-not $currentExclusions.ContainsKey($key)) {
          $exclusionsMatch = $false
          break
        }
      }
    }

    if ($exclusionsMatch) {
      Log "IDE file exclusions already set correctly, skipping"
      return
    }
  }

  # Build exclusion patterns - hide everything except specified items
  $Exclusions = @{}
  Get-ChildItem -LiteralPath $ProjectRoot -Force -ErrorAction SilentlyContinue | ForEach-Object {
    if ($KeepVisible -notcontains $_.Name) {
      # Use relative paths from project root
      $RelativePath = $_.Name
      if ($_.PSIsContainer) {
        $Exclusions["$RelativePath/**"] = $true
        $Exclusions["$RelativePath"] = $true
      } else {
        $Exclusions[$RelativePath] = $true
      }
    }
  }

  # Always exclude common development artifacts
  $Exclusions["**/.git"] = $true
  $Exclusions["**/.git/**"] = $true
  $Exclusions["**/.DS_Store"] = $true

  # Update files.exclude setting
  $Settings."files.exclude" = $Exclusions

  # Write settings back
  try {
    $Settings | ConvertTo-Json -Depth 10 | Set-Content $SettingsPath -Encoding UTF8
    Log "IDE file exclusions set successfully"
  } catch {
    Log "ERROR: Failed to write IDE settings: $($_.Exception.Message)"
    throw "Failed to configure IDE file exclusions"
  }
}

function Remove-IdeFileExclusions {
  param([Parameter(Mandatory=$true)][string]$ProjectRoot)

  Log "Removing IDE file exclusions (revealing all files)"

  $SettingsPath = Join-Path $ProjectRoot ".vscode\settings.json"

  if (-not (Test-Path $SettingsPath)) {
    Log "No settings file found, nothing to remove"
    return
  }

  try {
    $Settings = Get-Content $SettingsPath -Raw | ConvertFrom-Json

    # Remove files.exclude setting
    if ($Settings.PSObject.Properties.Name -contains "files.exclude") {
      $Settings.PSObject.Properties.Remove("files.exclude")
      Log "Removed files.exclude setting"
    }

    # Write back (or delete if empty)
    if ($Settings.PSObject.Properties.Count -eq 0) {
      Remove-Item $SettingsPath -Force
      Log "Removed empty settings file"
    } else {
      $Settings | ConvertTo-Json -Depth 10 | Set-Content $SettingsPath -Encoding UTF8
      Log "Updated settings file (removed exclusions)"
    }

  } catch {
    Log "ERROR: Failed to remove IDE exclusions: $($_.Exception.Message)"
    throw "Failed to remove IDE file exclusions"
  }

  Write-Host "All files revealed in IDE!" -ForegroundColor Green
}

function Install-DevelopmentTools {
  Log "Installing/updating development tools..."

  $tools = @(
    @{Name = "UV (Python package manager)"; Command = "uv"; WingetId = "astral-sh.uv"; Required = $true},
    @{Name = "Bun (JavaScript runtime)"; Command = "bun"; WingetId = "Oven-sh.Bun"; Required = $false},
    @{Name = "Git"; Command = "git"; WingetId = "Git.Git"; Required = $true}
  )

  $installCount = 0
  foreach ($tool in $tools) {
    if (-not (Get-Command $tool.Command -ErrorAction SilentlyContinue)) {
      Write-Host "Installing $($tool.Name)..." -ForegroundColor Yellow

      try {
        $installCmd = "winget install --id $($tool.WingetId) --accept-source-agreements --accept-package-agreements"
        Log "Running: $installCmd"
        Invoke-Expression $installCmd

        if ($LASTEXITCODE -eq 0) {
          Write-Host "✅ $($tool.Name) installed successfully" -ForegroundColor Green
          $installCount++
        } else {
          if ($tool.Required) {
            Write-Host "❌ Failed to install required tool: $($tool.Name)" -ForegroundColor Red
            throw "Required tool installation failed: $($tool.Name)"
          } else {
            Write-Host "⚠️  Optional tool installation failed: $($tool.Name)" -ForegroundColor Yellow
          }
        }
      } catch {
        if ($tool.Required) {
          throw "Failed to install required tool: $($tool.Name)"
        } else {
          Log "Optional tool installation failed: $($tool.Name) - $($_.Exception.Message)"
        }
      }
    } else {
      Write-Host "✅ $($tool.Name) already installed" -ForegroundColor Green
    }
  }

  if ($installCount -gt 0) {
    Write-Host "`n🔄 Refreshing environment PATH..." -ForegroundColor Cyan
    # Refresh PATH for current session
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
  }

  Log "Development tools installation complete. Installed: $installCount tools"
}

function Update-PythonEnvironment {
  Log "Updating Python environment and dependencies..."

  # Check if Python needs updating
  $pythonVersion = & python --version 2>$null
  Log "Current Python version: $pythonVersion"

  # Update pip/setuptools/wheel first
  Write-Host "Updating pip, setuptools, and wheel..." -ForegroundColor Cyan
  & python -m pip install --upgrade pip setuptools wheel

  # If UV is available, ensure it's up to date
  if (Get-Command uv -ErrorAction SilentlyContinue) {
    Write-Host "Updating UV..." -ForegroundColor Cyan
    & uv self update
  }

  # Update dependencies if requirements.txt exists
  if (Test-Path "requirements.txt") {
    Write-Host "Updating Python dependencies..." -ForegroundColor Cyan

    if (Get-Command uv -ErrorAction SilentlyContinue) {
      # Use UV for faster, more reliable installs
      & uv pip install --upgrade -r requirements.txt
    } else {
      # Fallback to pip
      & python -m pip install --upgrade -r requirements.txt
    }

    if ($LASTEXITCODE -eq 0) {
      Write-Host "✅ Python dependencies updated" -ForegroundColor Green
    } else {
      Write-Host "⚠️  Some dependencies may have failed to update" -ForegroundColor Yellow
    }
  }

  Log "Python environment update complete"
}

function Apply-KnownIssueFixes {
  Log "Applying fixes for known issues from REPORT.md..."

  $fixesApplied = 0

  # Fix 1: PowerShell syntax issues (param block placement)
  # This is already fixed in the script structure

  # Fix 2: Virtual environment validation
  # This is already implemented in New-VirtualEnvironment

  # Fix 3: PowerShell extension stability settings
  Write-Host "Ensuring PowerShell extension stability settings..." -ForegroundColor Cyan
  $cursorSettingsPath = "$env:APPDATA\Cursor\User\settings.json"

  if (Test-Path $cursorSettingsPath) {
    try {
      $settings = Get-Content $cursorSettingsPath -Raw | ConvertFrom-Json

      # Apply stability fixes from REPORT.md
      $stabilitySettings = @{
        "powershell.integratedConsole.showOnStartup" = $false
        "powershell.startAutomatically" = $false
        "powershell.enableProfileLoading" = $false
        "powershell.sideBar.CommandExplorerVisibility" = $false
      }

      $settingsChanged = $false
      foreach ($setting in $stabilitySettings.GetEnumerator()) {
        if (-not $settings.($setting.Key) -or $settings.($setting.Key) -ne $setting.Value) {
          $settings | Add-Member -MemberType NoteProperty -Name $setting.Key -Value $setting.Value -Force
          $settingsChanged = $true
        }
      }

      if ($settingsChanged) {
        $settings | ConvertTo-Json -Depth 10 | Set-Content $cursorSettingsPath -Encoding UTF8
        Write-Host "✅ PowerShell extension stability settings applied" -ForegroundColor Green
        $fixesApplied++
      } else {
        Write-Host "✅ PowerShell extension stability settings already correct" -ForegroundColor Green
      }
    } catch {
      Log "WARNING: Could not apply PowerShell stability settings: $($_.Exception.Message)"
    }
  }

  # Fix 4: Execution Policy check
  Write-Host "Checking Execution Policy..." -ForegroundColor Cyan
  $currentPolicy = Get-ExecutionPolicy
  if ($currentPolicy -notin @("RemoteSigned", "Unrestricted")) {
    Write-Host "Setting Execution Policy to RemoteSigned..." -ForegroundColor Yellow
    try {
      Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
      Write-Host "✅ Execution Policy updated" -ForegroundColor Green
      $fixesApplied++
    } catch {
      Write-Host "⚠️  Could not update Execution Policy (may require admin rights)" -ForegroundColor Yellow
    }
  } else {
    Write-Host "✅ Execution Policy already correct" -ForegroundColor Green
  }

  # Fix 5: UTF-8 encoding (already implemented in script)

  Write-Host "`n📋 Issue fixes applied: $fixesApplied" -ForegroundColor Cyan
  Log "Applied $fixesApplied known issue fixes"
}

function Setup-MCPServers {
  Log "Setting up MCP (Model Context Protocol) servers..."

  # Check if MCP configuration directory exists
  $mcpConfigDir = Join-Path $ProjectRoot ".cursor\mcp"
  if (-not (Test-Path $mcpConfigDir)) {
    New-Item -ItemType Directory -Path $mcpConfigDir -Force | Out-Null
  }

  # Setup cursor-ide-browser MCP server (already available)
  $browserConfigPath = Join-Path $mcpConfigDir "browser.json"
  if (-not (Test-Path $browserConfigPath)) {
    @{
      "mcpServers" = @{
        "cursor-ide-browser" = @{
          "command" = "cursor-ide-browser"
          "args" = @()
          "env" = @{}
        }
      }
    } | ConvertTo-Json -Depth 10 | Set-Content $browserConfigPath -Encoding UTF8
    Write-Host "✅ MCP browser server configured" -ForegroundColor Green
  }

  # Additional MCP server configurations can be added here
  Write-Host "✅ MCP servers setup complete" -ForegroundColor Green
  Log "MCP servers setup complete"
}

function Setup-IntelliSense {
  Log "Configuring IntelliSense and language services..."

  # Python IntelliSense settings
  $pythonSettings = @{
    "python.defaultInterpreterPath" = ".\.venv\Scripts\python.exe"
    "python.terminal.activateEnvironment" = $true
    "python.linting.enabled" = $true
    "python.linting.pylintEnabled" = $true
  }

  # JavaScript/TypeScript IntelliSense settings
  $jsSettings = @{
    "typescript.preferences.includePackageJsonAutoImports" = "auto"
    "javascript.preferences.includePackageJsonAutoImports" = "auto"
  }

  # Apply settings to Cursor
  $cursorSettingsPath = "$env:APPDATA\Cursor\User\settings.json"

  try {
    if (Test-Path $cursorSettingsPath) {
      $settings = Get-Content $cursorSettingsPath -Raw | ConvertFrom-Json
    } else {
      $settings = @{}
    }

    $settingsChanged = $false

    # Apply Python settings
    foreach ($setting in $pythonSettings.GetEnumerator()) {
      if (-not $settings.($setting.Key) -or $settings.($setting.Key) -ne $setting.Value) {
        $settings | Add-Member -MemberType NoteProperty -Name $setting.Key -Value $setting.Value -Force
        $settingsChanged = $true
      }
    }

    # Apply JS settings
    foreach ($setting in $jsSettings.GetEnumerator()) {
      if (-not $settings.($setting.Key) -or $settings.($setting.Key) -ne $setting.Value) {
        $settings | Add-Member -MemberType NoteProperty -Name $setting.Key -Value $setting.Value -Force
        $settingsChanged = $true
      }
    }

    if ($settingsChanged) {
      $settings | ConvertTo-Json -Depth 10 | Set-Content $cursorSettingsPath -Encoding UTF8
      Write-Host "✅ IntelliSense settings applied" -ForegroundColor Green
    } else {
      Write-Host "✅ IntelliSense settings already configured" -ForegroundColor Green
    }

  } catch {
    Log "WARNING: Could not apply IntelliSense settings: $($_.Exception.Message)"
    Write-Host "⚠️  IntelliSense configuration skipped" -ForegroundColor Yellow
  }

  Log "IntelliSense configuration complete"
}

function Apply-AllSettings {
  Log "Applying all IDE and development settings..."

  Write-Host "🚀 Applying comprehensive settings..." -ForegroundColor Cyan

  # Apply Cursor settings
  $cursorResult = Set-CursorSettings
  if ($cursorResult) {
    Write-Host "✅ Cursor settings applied" -ForegroundColor Green
  }

  # Setup IntelliSense
  Setup-IntelliSense

  # Apply IDE file exclusions for clean view
  if (Test-Path "src") {
    Set-IdeFileExclusions -ProjectRoot $ProjectRoot -KeepVisible @("src")
    Write-Host "✅ IDE file exclusions configured" -ForegroundColor Green
  }

  Log "All settings applied successfully"
}

function Invoke-ComprehensiveSetup {
  Log "Starting comprehensive development environment setup..."

  Write-Host "🚀 COMPREHENSIVE SETUP STARTING" -ForegroundColor Cyan
  Write-Host "=" * 50 -ForegroundColor Cyan
  Write-Host ""

  $startTime = Get-Date

  try {
    # Step 1: Install/Update Tools
    Write-Host "📦 Step 1: Installing/Updating Development Tools" -ForegroundColor Yellow
    Install-DevelopmentTools
    Write-Host ""

    # Step 2: Apply Issue Fixes
    Write-Host "🔧 Step 2: Applying Known Issue Fixes" -ForegroundColor Yellow
    Apply-KnownIssueFixes
    Write-Host ""

    # Step 3: Update Python Environment
    Write-Host "🐍 Step 3: Updating Python Environment" -ForegroundColor Yellow
    Update-PythonEnvironment
    Write-Host ""

    # Step 4: Setup Environment
    Write-Host "⚙️  Step 4: Setting up Project Environment" -ForegroundColor Yellow
    New-VirtualEnvironment
    Install-PythonDependencies
    if (Test-Path "package.json") { Install-JavaScriptDependencies }
    Write-Host ""

    # Step 5: Apply All Settings
    Write-Host "🎨 Step 5: Applying IDE and Development Settings" -ForegroundColor Yellow
    Apply-AllSettings
    Write-Host ""

    # Step 6: Setup MCP
    Write-Host "🤖 Step 6: Setting up MCP Servers" -ForegroundColor Yellow
    Setup-MCPServers
    Write-Host ""

    # Step 7: Bootstrap Project
    Write-Host "📁 Step 7: Bootstrapping Project Files" -ForegroundColor Yellow
    Invoke-Bootstrap
    Write-Host ""

    # Step 8: Final Validation
    Write-Host "✅ Step 8: Running Final Validation" -ForegroundColor Yellow
    Invoke-DoctorCheck

    $duration = (Get-Date) - $startTime

    Write-Host ""
    Write-Host "🎉 COMPREHENSIVE SETUP COMPLETE!" -ForegroundColor Green
    Write-Host "=" * 50 -ForegroundColor Green
    Write-Host "Duration: $($duration.TotalSeconds.ToString("F1")) seconds" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Your development environment is now fully configured!" -ForegroundColor Green
    Write-Host "Run '.\run.ps1' to start developing." -ForegroundColor Cyan

    Log "Comprehensive setup completed successfully in $($duration.TotalSeconds) seconds"

  } catch {
    Write-Host ""
    Write-Host "❌ SETUP FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check the log file for details: $LogFile" -ForegroundColor Yellow
    Log "Setup failed: $($_.Exception.Message)"
    throw
  }
}

# Legacy functions for backward compatibility (deprecated)
function Set-HiddenItem {
  param([string]$Path)
  Log "WARNING: Set-HiddenItem is deprecated. Use Set-IdeFileExclusions instead."
}

function Hide-AllExcept {
  param([string]$Root, [string[]]$KeepNames = @("src"))
  Log "WARNING: Hide-AllExcept is deprecated. Use Set-IdeFileExclusions instead."
}

function Show-All {
  param([string]$Root)
  Log "WARNING: Show-All is deprecated. Use Remove-IdeFileExclusions instead."
  Remove-IdeFileExclusions -ProjectRoot $Root
}

function New-Project {
  param([string]$Name, [string]$DestRoot)

  Log "Creating new project: $Name"
  $Dest = Join-Path $DestRoot $Name

  if (Test-Path -LiteralPath $Dest) {
    Log "ERROR: Destination already exists: $Dest"
    Write-Host "ERROR: Destination already exists: $Dest" -ForegroundColor Red
    return $false
  }

  New-Item -ItemType Directory -Path $Dest -Force | Out-Null
  Log "Created directory: $Dest"

  # Copy everything except local artifacts
  $ExcludeDirs = @(".git", ".venv", "node_modules", "logs")
  $ExcludeFiles = @("*.log", "REPORT.md")

  $CopyArgs = @(
    $ProjectRoot,
    $Dest,
    "/MIR",
    "/XD"
  ) + $ExcludeDirs + @(
    "/XF"
  ) + $ExcludeFiles + @(
    "/R:2",
    "/W:1",
    "/NFL", "/NDL", "/NJH", "/NJS"
  )

  robocopy @CopyArgs | Out-Null

  # Fresh per-project report file
  @"
# Report

This file is the running log for issues encountered while working in this workspace (especially terminal/tooling problems in Cursor on Windows).

## Issues

"@ | Out-File -Encoding utf8 (Join-Path $Dest "REPORT.md")

  Log "Setting up new project automatically..."

  # Change to the new project directory
  Push-Location $Dest

  try {
    # Apply bootstrap
    Log "Applying bootstrap..."
    Invoke-Bootstrap

    # Apply Cursor settings
    Log "Applying Cursor settings..."
    $cursorResult = Set-CursorSettings
    if (-not $cursorResult) {
      Log "WARNING: Failed to apply Cursor settings"
      Write-Host "WARNING: Failed to apply Cursor settings" -ForegroundColor Yellow
    }

    # Apply VSCode settings if they exist in template
    $VSCodeSettingsSource = Join-Path $ProjectRoot ".vscode\settings.json"
    $VSCodeSettingsDest = Join-Path $Dest ".vscode\settings.json"
    if (Test-Path $VSCodeSettingsSource) {
      $VSCodeDir = Split-Path $VSCodeSettingsDest -Parent
      if (-not (Test-Path $VSCodeDir)) {
        New-Item -ItemType Directory -Path $VSCodeDir -Force | Out-Null
      }
      Copy-Item $VSCodeSettingsSource $VSCodeSettingsDest -Force
      Log "Applied VSCode settings"
    }

    # Apply Cursor rules if they exist in template
    $CursorRulesSource = Join-Path $ProjectRoot ".cursor\rules"
    $CursorRulesDest = Join-Path $Dest ".cursor\rules"
    if (Test-Path $CursorRulesSource) {
      if (-not (Test-Path $CursorRulesDest)) {
        New-Item -ItemType Directory -Path $CursorRulesDest -Force | Out-Null
      }
      Copy-Item "$CursorRulesSource\*" $CursorRulesDest -Recurse -Force
      Log "Applied Cursor rules"
    }

    Log "New project setup complete"
    Write-Host "Project setup complete!" -ForegroundColor Green

    # Ensure the ONE visible folder exists
    New-Item -ItemType Directory -Path (Join-Path $Dest "src") -Force | Out-Null
    Log "Created src\ directory"

    # Set IDE exclusions to hide everything else (including run.ps1)
    Set-IdeFileExclusions -ProjectRoot $Dest -KeepVisible @("src")
    Log "Set IDE file exclusions to hide all files/folders except src\"

  } finally {
    # Always return to original directory
    Pop-Location
  }

  Log "New project created and configured: $Dest"
  Write-Host "Created and configured: $Dest" -ForegroundColor Green
  Write-Host "Ready to use! Run:" -ForegroundColor Cyan
  Write-Host "  cd `"$Dest`"" -ForegroundColor DarkGray
  Write-Host "  .\run.ps1" -ForegroundColor DarkGray
  return $true
}

function Invoke-DoctorCheck {
  Log "Running comprehensive environment diagnostics..."

  Write-Host "SETUP CURSOR - ENVIRONMENT DIAGNOSTICS" -ForegroundColor Cyan
  Write-Host "=" * 50 -ForegroundColor Cyan
  Write-Host ""

  # PowerShell Version Check
  Write-Host "PowerShell Version:" -ForegroundColor Yellow
  $psVersion = $PSVersionTable.PSVersion
  Write-Host "  Current: $psVersion" -ForegroundColor $(if ($psVersion.Major -ge 7) { "Green" } else { "Red" })

  if ($psVersion.Major -lt 7) {
    Write-Host "  WARNING: PowerShell 7+ recommended for best Cursor compatibility" -ForegroundColor Yellow
    Write-Host "     Install: winget install --id Microsoft.PowerShell --source winget" -ForegroundColor Gray
  } else {
    Write-Host "  OK: PowerShell 7+ detected" -ForegroundColor Green
  }
  Write-Host ""

  # Execution Policy Check
  Write-Host "Execution Policy:" -ForegroundColor Yellow
  $execPolicy = Get-ExecutionPolicy
  Write-Host "  Current: $execPolicy" -ForegroundColor $(if ($execPolicy -in @("RemoteSigned", "Unrestricted")) { "Green" } else { "Red" })

  if ($execPolicy -notin @("RemoteSigned", "Unrestricted")) {
    Write-Host "  WARNING: Execution policy may block script execution" -ForegroundColor Yellow
    Write-Host "     Fix: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Gray
  } else {
    Write-Host "  OK: Execution policy allows script execution" -ForegroundColor Green
  }
  Write-Host ""

  # Tool Checks
  Write-Host "Development Tools:" -ForegroundColor Yellow

  $tools = @(
    @{Name = "Git"; Command = "git"; Required = $true; InstallCmd = "winget install --id Git.Git"},
    @{Name = "Python"; Command = "python"; Required = $true; InstallCmd = "winget install Python.Python.3"},
    @{Name = "UV (Python package manager)"; Command = "uv"; Required = $false; InstallCmd = "winget install astral-sh.uv"},
    @{Name = "Bun (JavaScript runtime)"; Command = "bun"; Required = $false; InstallCmd = "winget install -e --id Oven-sh.Bun"}
  )

  foreach ($tool in $tools) {
    $toolInfo = & { try { Get-Command $tool.Command -ErrorAction SilentlyContinue } catch { $null } }

    if ($toolInfo) {
      $version = & { try { & $tool.Command --version 2>$null } catch { "unknown" } }
      Write-Host "  OK: $($tool.Name): $version" -ForegroundColor Green

      # Special checks for Python
      if ($tool.Command -eq "python") {
        $pyVersion = & { try { & python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>$null } catch { "unknown" } }
        if ($pyVersion -and [version]$pyVersion -lt [version]"3.8") {
          Write-Host "     WARNING: Python 3.8+ recommended, found $pyVersion" -ForegroundColor Yellow
        }
      }
    } else {
      if ($tool.Required) {
        Write-Host "  MISSING: $($tool.Name) (required)" -ForegroundColor Red
        Write-Host "     Install: $($tool.InstallCmd)" -ForegroundColor Gray
      } else {
        Write-Host "  MISSING: $($tool.Name) (optional)" -ForegroundColor Yellow
        Write-Host "    Install: $($tool.InstallCmd)" -ForegroundColor Gray
      }
    }
  }
  Write-Host ""

  # PATH Analysis
  Write-Host "PATH Analysis:" -ForegroundColor Yellow

  $pathIssues = @()
  $pathDirs = $env:PATH -split ';' | Where-Object { $_ -and (Test-Path $_) }

  # Check for common issues
  $pythonPaths = $pathDirs | Where-Object { $_ -like "*python*" -or $_ -like "*Python*" }
  if ($pythonPaths.Count -eq 0) {
    $pathIssues += "No Python directories found in PATH"
  }

  # Check for duplicate entries
  $duplicateDirs = $pathDirs | Group-Object | Where-Object { $_.Count -gt 1 }
  if ($duplicateDirs) {
    $pathIssues += "$($duplicateDirs.Count) duplicate PATH entries found"
  }

  if ($pathIssues.Count -eq 0) {
    Write-Host "  OK: PATH looks clean" -ForegroundColor Green
  } else {
    Write-Host "  ISSUES: PATH problems found:" -ForegroundColor Yellow
    foreach ($issue in $pathIssues) {
      Write-Host "     - $issue" -ForegroundColor Yellow
    }
  }
  Write-Host ""

  # Environment Variables
  Write-Host "Environment Variables:" -ForegroundColor Yellow

  $keyVars = @("HOME", "USERPROFILE", "APPDATA", "LOCALAPPDATA")
  foreach ($var in $keyVars) {
    $value = [Environment]::GetEnvironmentVariable($var)
    if ($value) {
      Write-Host "  OK: $var`: $(if ($value.Length -gt 50) { $value.Substring(0,47) + '...' } else { $value })" -ForegroundColor Green
    } else {
      Write-Host "  MISSING: $var`: NOT SET" -ForegroundColor Yellow
    }
  }
  Write-Host ""

  # Cursor/IDE Integration
  Write-Host "Cursor/IDE Integration:" -ForegroundColor Yellow

  $cursorSettingsPath = "$env:APPDATA\Cursor\User\settings.json"
  if (Test-Path $cursorSettingsPath) {
    Write-Host "  OK: Cursor settings file exists" -ForegroundColor Green
  } else {
    Write-Host "  MISSING: Cursor settings file not found" -ForegroundColor Yellow
    Write-Host "     Run: .\run.ps1 -ApplyCursorSettings" -ForegroundColor Gray
  }

  # Check if we're in a project directory
  if (Test-Path ".vscode") {
    Write-Host "  OK: VSCode/Cursor workspace detected" -ForegroundColor Green

    $settingsPath = ".vscode\settings.json"
    if (Test-Path $settingsPath) {
      Write-Host "  OK: Workspace settings file exists" -ForegroundColor Green

      try {
        $wsSettings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        if ($wsSettings."files.exclude") {
          Write-Host "  OK: File exclusions configured (clean view active)" -ForegroundColor Green
        } else {
          Write-Host "  INFO: No file exclusions (full view active)" -ForegroundColor Cyan
        }
      } catch {
        Write-Host "  WARNING: Could not parse workspace settings" -ForegroundColor Yellow
      }
    }
  } else {
    Write-Host "  INFO: Not in a Cursor workspace directory" -ForegroundColor Cyan
  }
  Write-Host ""

  # Recommendations
  Write-Host "Recommendations:" -ForegroundColor Yellow

  $recommendations = @()

  if ($psVersion.Major -lt 7) {
    $recommendations += "Upgrade to PowerShell 7+ for better Cursor compatibility"
  }

  if ($execPolicy -notin @("RemoteSigned", "Unrestricted")) {
    $recommendations += "Set execution policy: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
  }

  $missingRequired = $tools | Where-Object { $_.Required -and -not (Get-Command $_.Command -ErrorAction SilentlyContinue) }
  if ($missingRequired) {
    $recommendations += "Install missing required tools: $($missingRequired.Name -join ', ')"
  }

  if ($recommendations.Count -eq 0) {
    Write-Host "  SUCCESS: Your environment looks great! Ready for development." -ForegroundColor Green
  } else {
    foreach ($rec in $recommendations) {
      Write-Host "  - $rec" -ForegroundColor Cyan
    }
  }

  Write-Host ""
  Write-Host "Quick Fixes:" -ForegroundColor Yellow
  Write-Host "  - Apply Cursor settings: .\run.ps1 -ApplyCursorSettings" -ForegroundColor Gray
  Write-Host "  - Create new project: .\run.ps1 -NewProject 'my-project'" -ForegroundColor Gray
  Write-Host "  - Bootstrap current dir: .\run.ps1 -Bootstrap" -ForegroundColor Gray
  Write-Host "  - Run diagnostics again: .\run.ps1 -Doctor" -ForegroundColor Gray

  Log "Doctor check complete"
}

function Invoke-Bootstrap {
  Log "Bootstrapping project..."

  $filesCreated = 0

  if (-not (Test-Path ".gitignore")) {
    @"
.venv/
__pycache__/
*.pyc
node_modules/
dist/
build/
logs/
.DS_Store
"@ | Out-File -Encoding utf8 .gitignore
    Log "Created .gitignore"
    $filesCreated++
  } else {
    Log ".gitignore already exists, skipping"
  }

  if (-not (Test-Path "README.md")) {
    @"
# Project

## Run
```powershell
.\run.ps1
```

## Notes
- Use Cursor terminal in PowerShell 7 (pwsh) if possible.
- Prefer: edit files → run `.\run.ps1`
"@ | Out-File -Encoding utf8 README.md
    Log "Created README.md"
    $filesCreated++
  } else {
    Log "README.md already exists, skipping"
  }

  if (-not (Test-Path "REPORT.md")) {
    @"
# Report

This file is the running log for issues encountered while working in this workspace (especially terminal/tooling problems in Cursor on Windows).

## Issues

"@ | Out-File -Encoding utf8 REPORT.md
    Log "Created REPORT.md"
    $filesCreated++
  } else {
    Log "REPORT.md already exists, skipping"
  }

  # Copy Cursor settings template if it exists in scripts folder (for backward compatibility)
  $TemplateSource = Join-Path $PSScriptRoot "scripts\cursor-settings.json"
  if ((Test-Path $TemplateSource) -and -not (Test-Path "cursor-settings.json")) {
    Copy-Item $TemplateSource "cursor-settings.json"
    Log "Copied Cursor settings template."
    $filesCreated++
  }

  if ($filesCreated -gt 0) {
    Log "Bootstrap complete. Created $filesCreated file(s)."
    Write-Host "Bootstrap complete. Created $filesCreated file(s)." -ForegroundColor Green
  } else {
    Log "Bootstrap complete. All files already exist."
    Write-Host "Bootstrap complete. All files already exist." -ForegroundColor Green
  }
}

Log "== Startup =="
Import-Env

Log "== Preflight =="
Log "ProjectRoot: $ProjectRoot"
Log "LogFile: $LogFile"

# --- Tool checks ---
$required = @("pwsh", "python")
foreach ($t in $required) {
  if (-not (Get-Command $t -ErrorAction SilentlyContinue)) {
    Log "ERROR: Missing tool in PATH: $t"
    Write-Host "Missing tool in PATH: $t" -ForegroundColor Red
    Write-Host "Log: $LogFile" -ForegroundColor Yellow
    exit 1
  }
}

$optional = @("uv", "bun")
foreach ($t in $optional) {
  if (-not (Get-Command $t -ErrorAction SilentlyContinue)) {
    Log "WARN: Optional tool not found: $t"
  }
}

Log "== Resolution =="
Log ("pwsh: " + (where.exe pwsh | Select-Object -First 1))
Log ("py  : " + (where.exe python | Select-Object -First 1))
if (Get-Command uv  -ErrorAction SilentlyContinue) { Log ("uv  : " + (where.exe uv  | Select-Object -First 1)) }
if (Get-Command bun -ErrorAction SilentlyContinue) { Log ("bun : " + (where.exe bun | Select-Object -First 1)) }

Log "== Versions =="
Log ("pwsh " + (& pwsh -v))
Log ("python " + (& python --version))
if (Get-Command uv -ErrorAction SilentlyContinue)  { Log ("uv " + (& uv --version)) }
if (Get-Command bun -ErrorAction SilentlyContinue) { Log ("bun " + (& bun -v)) }

# --- SUGGESTION 2: Cleaning Functionality ---
if ($Clean) {
    Log "Cleaning project artifacts..."
    $Artifacts = @(".venv", "node_modules", "dist", "build", "__pycache__", "*.egg-info")

    foreach ($item in $Artifacts) {
        if (Test-Path $item) {
            Log "Removing $item..."
            Remove-Item -Path $item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # Clean pyc files recursively
    Get-ChildItem -Path . -Filter "*.pyc" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force

    Log "Cleanup complete."
    Write-Host "Project cleaned successfully." -ForegroundColor Green
    exit 0
}

# Handle special modes
if ($Setup) {
  Invoke-ComprehensiveSetup
  exit 0
}

if ($InstallTools) {
  Install-DevelopmentTools
  exit 0
}

if ($UpdatePython) {
  Update-PythonEnvironment
  exit 0
}

if ($FixIssues) {
  Apply-KnownIssueFixes
  exit 0
}

if ($ApplyAllSettings) {
  Apply-AllSettings
  exit 0
}

if ($SetupMCP) {
  Setup-MCPServers
  exit 0
}

if ($Doctor) {
  Invoke-DoctorCheck
  exit 0
}

if ($NewProject) {
  $result = New-Project -Name $NewProject -DestRoot $DestinationRoot
  exit $(if ($result) { 0 } else { 1 })
}

if ($Bootstrap) {
  Invoke-Bootstrap
  exit 0
}

if ($PreflightOnly) {
  Log "PreflightOnly enabled; exiting 0."
  Write-Host "Preflight OK. Log: $LogFile" -ForegroundColor Green
  exit 0
}

# --- Apply Cursor Settings (if requested) ---
if ($ApplyCursorSettings) {
  $result = Set-CursorSettings
  if (-not $result) {
    Log "ERROR: Failed to apply Cursor settings"
    exit 1
  }
}

# --- Python setup (UV preferred) ---
$PythonReady = $false
if (Get-Command uv -ErrorAction SilentlyContinue) {
    if (-not (Test-Path ".\.venv\Scripts\python.exe")) {
        try {
            New-VirtualEnvironment
        }
        catch {
            Log "ERROR: Virtual environment setup failed: $($_.Exception.Message)"
            exit 1
        }
    }

    # FIXED: Proper dependency installation with error handling
    try {
        Install-PythonDependencies
        $PythonReady = $true
    }
    catch {
        Log "ERROR: Python dependency installation failed: $($_.Exception.Message)"
        exit 1
    }
}

# --- JS setup (Bun) ---
$JsReady = $false
if ((Get-Command bun -ErrorAction SilentlyContinue) -and (Test-Path ".\package.json")) {
    try {
        Install-JavaScriptDependencies
        $JsReady = $true
    }
    catch {
        Log "ERROR: JavaScript dependency installation failed: $($_.Exception.Message)"
        exit 1
    }
}

# --- Run entrypoint (Python preferred if present) ---
Log "== Run =="

if (Test-Path $PythonEntrypoint) {
  if ($PythonReady -and (Test-Path ".\.venv\Scripts\python.exe")) {
    Log "Running Python entrypoint via .venv: $PythonEntrypoint"
    & ".\.venv\Scripts\python.exe" $PythonEntrypoint 2>&1 | Tee-Object -FilePath $LogFile -Append
    exit $LASTEXITCODE
  } else {
    Log "Running Python entrypoint via system python: $PythonEntrypoint"
    python $PythonEntrypoint 2>&1 | Tee-Object -FilePath $LogFile -Append
    exit $LASTEXITCODE
  }
}

if ($JsReady) {
  Log "Running JS script via bun: $JsScript"
  bun run $JsScript 2>&1 | Tee-Object -FilePath $LogFile -Append
  exit $LASTEXITCODE
}

# 2. SUGGESTION 3: Interactive Dashboard (if no entrypoint found)
if ($Host.UI.RawUI) {
    try { Clear-Host } catch { }
}
Write-Host "== SETUP PROJECT DASHBOARD ==" -ForegroundColor Cyan
Write-Host "Project: $ProjectRoot" -ForegroundColor DarkGray
Write-Host ""

Write-Host " [1] Run Python Entrypoint (main.py)"
Write-Host " [2] Run JS Entrypoint (bun run $JsScript)"
Write-Host " [3] Apply Cursor/VSCode Settings"
Write-Host " [4] Clean Project (Reset venv/modules)"
Write-Host " [5] Reveal hidden project files"
Write-Host " [6] Run Comprehensive Setup (winget-like)"
Write-Host " [7] Install/Update Development Tools"
Write-Host " [8] Update Python Environment"
Write-Host " [9] Apply Known Issue Fixes"
Write-Host " [Q] Quit"
Write-Host ""

$Selection = Read-Host "Select an option"

switch ($Selection) {
    "1" {
        if (Test-Path "main.py") { & $PythonRunner "main.py" }
        else { Write-Host "main.py not found" -ForegroundColor Red }
    }
    "2" {
        if ($JsReady) { bun run $JsScript }
        else { Write-Host "Bun or package.json missing" -ForegroundColor Red }
    }
    "3" { Set-CursorSettings }
    "4" { & $MyInvocation.MyCommand.Path -Clean }
    "5" { Remove-IdeFileExclusions -ProjectRoot $ProjectRoot }
    "6" { Invoke-ComprehensiveSetup }
    "7" { Install-DevelopmentTools }
    "8" { Update-PythonEnvironment }
    "9" { Apply-KnownIssueFixes }
    "Q" { exit 0 }
    Default { Write-Host "Invalid selection" -ForegroundColor Yellow }
}