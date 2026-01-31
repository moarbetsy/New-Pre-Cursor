# Security Policy

## Supported Versions

We actively support security updates for the current version of this repository template.

## Reporting a Vulnerability

If you discover a security vulnerability, please **do not** open a public issue. Instead, please report it privately:

1. **Email**: [Your security contact email]
2. **Subject**: `[SECURITY]` followed by a brief description

Please include:

- A description of the vulnerability
- Steps to reproduce the issue
- Potential impact
- Any suggested fixes (if available)

We will acknowledge receipt of your report within 48 hours and provide an update on the status of the vulnerability within 7 days.

## Security Best Practices

This repository template emphasizes:

- **Lockfile enforcement**: All dependencies are pinned via lockfiles (`bun.lock`, `uv.lock`)
- **Frozen installs**: CI and development workflows use `--frozen-lockfile` / `--frozen` flags
- **Toolchain pinning**: All tool versions are explicitly pinned (`.bun-version`, `.python-version`, `rust-toolchain.toml`)
- **Check-mode CI**: CI runs in check-mode only, preventing accidental modifications

When using this template:

- Keep dependencies up to date
- Review lockfile changes carefully
- Run `just ci` before committing
- Report security issues promptly
