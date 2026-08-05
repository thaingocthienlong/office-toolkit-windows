# Task 6 report: setup, smoke verification, packaging, and private install

## Delivered

- Added idempotent root `setup.ps1` with Windows x64, `codex.cmd`, and Python 3.11+ x64 checks.
- Created `%LOCALAPPDATA%\Codex\office-toolkit-windows\venv` and verified the six direct locked dependencies.
- Added `-Check` mode; normal setup and the check path both avoid reinstalling an already matching environment.
- Registered the local marketplace and installed the plugin only when the manifest hash or source path changes.
- Added `tests/Smoke.ps1` and `package.ps1`.
- Updated README with install, update, uninstall, and new-task visibility instructions.

## Verification

```text
setup.ps1
office-toolkit-windows setup passed

setup.ps1 (second run)
office-toolkit-windows setup passed

setup.ps1 -Check
office-toolkit-windows check passed

tests/Smoke.ps1
SMOKE PASS: setup x2, OfficeCLI PATH/fallback, DOCX/PPTX/XLSX, PDF resume/export, and cleanup guards

python -m unittest tests.test_pdf_pipeline
Ran 16 tests ... OK

Invoke-Pester -Script .\tests\Invoke-OfficeCli.Tests.ps1 -PassThru
Passed: 2 Failed: 0 Skipped: 0

quick_validate.py
Skill is valid! (office-docx, office-pptx, office-xlsx, pdf-scan-to-docx)

validate_plugin.py
Plugin validation passed
```

The first post-setup Pester run saw a one-time OfficeCLI skill-refresh message on bundled `--version`; the wrapper preserved that native stream. The test now checks the fallback version at the end of the stream and passes on repeat.

## Package verification

`package.ps1` created `dist/office-toolkit-windows-v0.1.0.zip` and its SHA-256 file. The final archive contains 428 entries, includes `.agents/plugins/marketplace.json`, the plugin manifest, `setup.ps1`, and `README.md`, and contains zero tests, caches, bytecode, or secret filenames.

Final SHA-256:

```text
4723d5df16df159f2e91666cdda4fde6329b325075f5458f70ec4a58fd5660c2
```

The final ZIP was extracted to a temporary profile directory, installed successfully, reported `office-toolkit-windows@office-toolkit-windows (installed, enabled)`, exposed exactly four skill directories, and the marketplace was restored to the repository checkout afterward.

## Private release

- Private repository: `https://github.com/thaingocthienlong/office-toolkit-windows`
- Tag and release: `v0.1.0`
- Release page: `https://github.com/thaingocthienlong/office-toolkit-windows/releases/tag/v0.1.0`
- Uploaded assets: `office-toolkit-windows-v0.1.0.zip` and `.sha256`

Independent final re-review remains pending: local `codex review --uncommitted` timed out after the CLI/model compatibility retry, and the separate read-only reviewer also timed out twice before shutdown. No clean review result is claimed.

- Public release remains prohibited until the existing source/template/OfficeCLI provenance and redistribution audit is complete.
