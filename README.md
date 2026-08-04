# Office Toolkit Windows

Private-use Windows 10/11 x64 plugin foundation for Office and scanned PDF workflows.

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

Task 6 will add repeatable setup and smoke verification. These commands perform current local marketplace discovery and installation only.

Current package boundary: no public skills, setup logic, OfficeCLI wrapper, or PDF runtime. See `plugins/office-toolkit-windows/PACKAGE_BOUNDARIES.md` and `plugins/office-toolkit-windows/THIRD_PARTY_NOTICES.md` before redistribution.
