# Module manifest for setup-cursor
# Submit to PowerShell Gallery with: Publish-Module -Path .\setup-cursor -NuGetApiKey "your_api_key"

@{
    # Script module or binary module file associated with this manifest
    RootModule = 'setup-cursor.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0'

    # ID used to uniquely identify this module
    GUID = '12345678-1234-1234-1234-123456789012'

    # Author of this module
    Author = 'Setup Cursor'

    # Company or vendor of this module
    CompanyName = 'Setup Cursor'

    # Copyright statement for this module
    Copyright = '(c) 2026 Setup Cursor. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'A comprehensive "winget-like" development environment setup tool for Cursor IDE + PowerShell. Installs tools, updates dependencies, applies settings, and fixes issues with a single command.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = @('setup-cursor')

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @('sc')

    # Private data to pass to the module specified in RootModule
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Cursor', 'PowerShell', 'Development', 'Setup', 'Winget', 'IDE', 'Environment')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/moarbetsy/setup-cursor/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/moarbetsy/setup-cursor'

            # ReleaseNotes of this module
            ReleaseNotes = @'
## v1.0.0
- Initial release of setup-cursor
- Complete environment setup with one command
- Global installation from any computer
- Winget-like package management
- Comprehensive IntelliSense configuration
- Automatic issue resolution
- MCP server setup
- Cross-platform Windows support
'@

        } # End of PSData hashtable

    } # End of PrivateData hashtable

}