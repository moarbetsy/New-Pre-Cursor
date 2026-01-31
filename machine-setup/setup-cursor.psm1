# setup-cursor.psm1
# PowerShell module for setup-cursor
# Import the profile script to make setup-cursor function available

# Get the module directory
$scriptPath = $MyInvocation.MyCommand.Path
if ($null -eq $scriptPath) {
    # Fallback for when script was executed via iex (no file path)
    $moduleDir = "$HOME\.setup-cursor"
} else {
    $moduleDir = Split-Path -Parent $scriptPath
}

# Import the profile script
$profileScriptPath = Join-Path $moduleDir "setup-cursor-profile.ps1"
if (Test-Path $profileScriptPath) {
    . $profileScriptPath
} else {
    Write-Warning "setup-cursor-profile.ps1 not found in module directory: $moduleDir"
}

# Export the function and alias
Export-ModuleMember -Function setup-cursor -Alias sc