# Precursor File Tree

```
precursor/
├── .gitignore                          # Git ignore patterns
├── .precursor/
│   └── mcp/
│       └── server.ts                   # MCP server implementation
├── LICENSE                             # MIT License
├── README.md                           # Main documentation
├── FILE_TREE.md                        # This file
├── biome.json                          # Biome configuration
├── package.json                        # Node.js/Bun package manifest
├── precursor.json                      # Default Precursor configuration
├── precursor.schema.json               # JSON Schema for validation
├── precursor.ps1                       # PowerShell entry point
├── src/
│   ├── index.ts                        # Main exports and orchestration
│   ├── cli.ts                          # CLI entry point
│   ├── config.ts                       # Configuration loading/validation
│   ├── merge.ts                        # Deep merge engine
│   ├── state.ts                        # State management with hashing
│   ├── detector.ts                     # Stack detection
│   ├── toolchain.ts                    # Tool resolution/installation
│   ├── doctor.ts                       # Doctor checks and fixes
│   ├── scaffold.ts                     # File scaffolding/generation
│   ├── ci.ts                           # GitHub Actions workflow generation
│   ├── secrets.ts                      # Secret scanning
│   ├── backup.ts                       # Backup and rollback
│   ├── merge.test.ts                   # Tests for merge
│   ├── state.test.ts                   # Tests for state
│   └── detector.test.ts                # Tests for detector
└── tsconfig.json                       # TypeScript configuration
```

## Key Directories

- **`src/`**: TypeScript core implementation
- **`.precursor/`**: Runtime state, backups, MCP server, portable binaries
- **`.cursor/`**: Generated Cursor rules (created by scaffold)
- **`.vscode/`**: Generated VS Code settings (created by scaffold)
- **`.github/workflows/`**: Generated CI workflows (created by scaffold)

## Generated Files (not in repo)

These files are created by `precursor.ps1 -Setup`:

- `.cursor/rules/*.mdc` - Stack-specific rules
- `.vscode/settings.json` - VS Code settings
- `.vscode/extensions.json` - Recommended extensions
- `.cursor/mcp.json` - MCP server configuration
- `.github/workflows/*.yml` - CI workflows
- `.precursor/state.json` - State cache
- `.precursor/backups/<timestamp>/` - Backup snapshots
