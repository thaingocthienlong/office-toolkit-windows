# Task 1 report - Repository and plugin foundation

## Completed scope

- Added local marketplace entry for `office-toolkit-windows`.
- Added skills-only plugin manifest, version `0.1.0`.
- Moved the three Office/PDF source trees to `plugins/office-toolkit-windows/assets/vendor`:
  - `boc-tach-pdf-v1.0`
  - `xu-ly-van-phong`
  - `xu-ly-van-phong-cli`
- Added root installation documentation, provenance, third-party notices, package boundaries, and the Task 1 empty dependency lock.
- Kept `assets/viet-chuyen-nghiep-v3.1` outside the plugin.

## Explicit exclusions

No public skills, setup logic, OfficeCLI wrapper, or PDF runtime were added.

## Validation

- `validate_plugin.py plugins/office-toolkit-windows`: passed.
- PowerShell `ConvertFrom-Json` parse for marketplace and plugin manifest: passed.
- `git diff --check`: passed.
- Vendor file counts: 18 (`boc-tach-pdf-v1.0`), 108 (`xu-ly-van-phong`), 277 (`xu-ly-van-phong-cli`).
- Confirmed `assets/viet-chuyen-nghiep-v3.1` remains present.

## Concerns

Vendor redistribution remains unverified. The package is private-use only until upstream licenses and notices are pinned. The dependency lock is intentionally empty because Task 1 does not activate a PDF runtime; Task 5 must add verified, pinned dependencies.

## Round 1 fix - local installation documentation

Updated `README.md` with current local marketplace discovery and installation commands. No setup logic was added.

Commands documented:

```powershell
codex.cmd plugin marketplace list
codex.cmd plugin marketplace add .
codex.cmd plugin list --marketplace office-toolkit-windows
codex.cmd plugin add office-toolkit-windows@office-toolkit-windows
```

Read-only command output before this fix:

```text
codex.cmd plugin marketplace list
mem0-plugins    C:\Users\Vien Phuong Nam\.codex\.tmp/marketplaces\mem0-plugins
openai-bundled  \\?\C:\Users\Vien Phuong Nam\.codex\.tmp\bundled-marketplaces\openai-bundled
openai-primary-runtime  \\?\C:\Users\Vien Phuong Nam\.cache\codex-runtimes\codex-primary-runtime\plugins\openai-primary-runtime
personal  \\?\C:\Users\Vien Phuong Nam\Documents\codex-operating-workflow-plugin
ponytail  C:\Users\Vien Phuong Nam\.codex\.tmp/marketplaces\ponytail
superpowers-mcp-augment  C:\Users\Vien Phuong Nam\.codex\.tmp/marketplaces\superpowers-mcp-augment

codex.cmd plugin list --marketplace office-toolkit-windows
No plugins found in marketplace `office-toolkit-windows`.
```

`codex.cmd plugin marketplace add .` and `codex.cmd plugin add office-toolkit-windows@office-toolkit-windows` were not run because this fix documents, but does not alter, local Codex installation state.

Focused validation output after the documentation change:

```text
Plugin validation passed: D:\Codex\office-skills\plugins\office-toolkit-windows
JSON parse: passed
git diff --check: passed
```
