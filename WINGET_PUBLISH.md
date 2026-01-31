# Publishing the PreCursor winget package

Use this flow to publish or update the PreCursor package so users can run `winget install PreCursor.PreCursor; precursor -Setup`.

---

## Prerequisites

- Repo is set to **MoarBetsy/New-Pre-Cursor**.
- Git, PowerShell 7, and a GitHub repo with push access.

---

## 1) Create a release

1. Tag and push a release (e.g. `v1.0.0`):

   ```powershell
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. On GitHub: **Releases** → **Draft a new release** → choose tag `v1.0.0`, set title (e.g. `v1.0.0`). Leave the release draft open for the next step.

---

## 2) ZIP the winget launcher

The ZIP must contain **only** the two launcher files at the **root** of the archive (no `winget-launcher` folder inside).

From the **repo root** in PowerShell:

```powershell
$out = "precursor-launcher-v1.0.0.zip"
if (Test-Path $out) { Remove-Item $out -Force }
Compress-Archive -Path "winget-launcher\precursor.cmd", "winget-launcher\precursor.ps1" -DestinationPath $out -CompressionLevel Optimal
Get-Item $out
```

Verify contents:

```powershell
# Should list precursor.cmd and precursor.ps1 at root
Expand-Archive -Path $out -DestinationPath (Join-Path $env:TEMP "precursor-zip-check") -Force
Get-ChildItem (Join-Path $env:TEMP "precursor-zip-check")
Remove-Item (Join-Path $env:TEMP "precursor-zip-check") -Recurse -Force
```

---

## 3) Get SHA256 and attach ZIP to release

```powershell
(Get-FileHash -Path "precursor-launcher-v1.0.0.zip" -Algorithm SHA256).Hash
```

- Copy the SHA256 string (no spaces, uppercase or lowercase both work for winget).
- Upload `precursor-launcher-v1.0.0.zip` as a release asset in the GitHub release draft.
- Publish the release.

---

## 4) Update the manifest

Edit **PreCursor.winget-manifest.yaml** at the repo root:

- **InstallerUrl**: set to the release asset URL, e.g.
  `https://github.com/MoarBetsy/New-Pre-Cursor/releases/download/v1.0.0/precursor-launcher-v1.0.0.zip`
- **InstallerSha256**: set to the value from step 3 (replace `REPLACE_WITH_ACTUAL_SHA256_AFTER_RELEASE`).

If you changed the version (e.g. to `1.0.1`), update **Version** in the manifest and the ZIP/URL to match.

---

## 5) Submit to winget-pkgs

1. Fork [microsoft/winget-pkgs](https://github.com/microsoft/winget-pkgs).
2. In your fork, add the manifest(s) under the winget-pkgs layout:
   - Manifests go under `manifests/<Publisher>/<PackageId>/<Version>/` (e.g. `manifests/p/PreCursor/PreCursor/1.0.0/`).
   - Use the [winget-pkgs documentation](https://github.com/microsoft/winget-pkgs/blob/master/AUTHORING_MANIFESTS.md) for the exact folder structure and file names (e.g. `PreCursor.PreCursor.yaml` for the version manifest, plus installer and locale files if required).
3. Open a PR from your fork to `microsoft/winget-pkgs` with your new or updated package.
4. Address any automation or review feedback.

---

## Summary checklist

- [ ] `MoarBetsy` replaced with your GitHub username everywhere.
- [ ] Release created and tag pushed.
- [ ] ZIP created with `precursor.cmd` and `precursor.ps1` at root.
- [ ] SHA256 computed and manifest updated.
- [ ] ZIP attached to release and release published.
- [ ] PR to winget-pkgs opened with correct manifest layout.
