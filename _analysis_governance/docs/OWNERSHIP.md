# Ownership Map (One Rewriter Per Extension)

Rewriter ownership (rewrite == format/fix):

- `*.py` → Ruff
- `*.ts, *.tsx, *.js, *.jsx, *.json` → Biome
- `*.css, *.scss, *.sass, *.html` → Biome (explicitly enabled)
- `*.md, *.yaml, *.yml, *.toml` → dprint
- Rust formatting → `cargo fmt`

Checkers (allowed in check-mode, no rewriting):

- Python types → Pyright
- Rust lint → Clippy
- PowerShell lint → PSScriptAnalyzer

## The Boss Rule

Many tools may CHECK. Exactly one tool may REWRITE a given extension.
