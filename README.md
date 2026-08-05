# Office Toolkit Windows

Private-use Windows 10/11 x64 toolkit for Office and scanned PDF workflows.

Task 1 adds the local marketplace at `.agents/plugins/marketplace.json`, the `office-toolkit-windows` plugin manifest, and vendored reference assets.

## Local discovery and installation

Run these commands from this repository root:

```powershell
# Check whether this local marketplace is already configured.
codex.cmd plugin marketplace list

# If `office-toolkit-windows` is absent, register this repository as a local marketplace.
codex.cmd plugin marketplace add .

# Discover the plugin, then install it from the local marketplace.
codex.cmd plugin list --marketplace office-toolkit-windows
codex.cmd plugin add office-toolkit-windows@office-toolkit-windows
```

## One-command setup

From the repository root, or the root of an extracted private ZIP:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1
```

The setup is idempotent. Re-running it checks the existing venv and locked dependency versions, and `-Check` performs the same checks without installing missing components:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1 -Check
```

Start a new Codex task after setup so the four skills become visible. Confirm installation with `codex.cmd plugin list --marketplace office-toolkit-windows`.

## Update and uninstall

Replace the checkout or extract a newer private ZIP over a new directory, then run `setup.ps1` again. The installer re-registers the local marketplace and reinstalls the plugin only when the package manifest changed.

To remove the Codex registration:

```powershell
codex.cmd plugin remove office-toolkit-windows@office-toolkit-windows
codex.cmd plugin marketplace remove office-toolkit-windows
Remove-Item -LiteralPath (Join-Path $env:LOCALAPPDATA 'Codex\office-toolkit-windows') -Recurse -Force
```

The last command removes only this toolkit's venv and installer stamp. It does not remove the repository or generated user documents.

Current package boundary: four public Office/PDF skills, the OfficeCLI wrapper, and local PDF runtime are active. Runtime network installers, MCP, apps, hooks, and the editorial `viet-chuyen-nghiep-v3.1` skill remain excluded. Redistribution is private-use only while the provenance and license audit is open; see `plugins/office-toolkit-windows/PACKAGE_BOUNDARIES.md` and `plugins/office-toolkit-windows/THIRD_PARTY_NOTICES.md`.
