# Task 5 report: `pdf-scan-to-docx` and shared runtime

## Status

Implemented from base `104a59c`.

## Scope delivered

- Added public `pdf-scan-to-docx` skill, bilingual trigger-only metadata, UI metadata, and a short project-owned OCR checkpoint reference.
- Added `skills/pdf-scan-to-docx/scripts/pipeline.py` with `prepare`, `render`, `preprocess`, `merge`, `export`, and `cleanup` commands.
- Added shared `scripts/invoke-officecli.ps1`.
- Replaced the empty lock with tested exact pins:
  - `PyMuPDF==1.27.2.3`
  - `Pillow==12.2.0`
  - `python-docx==1.2.0`
- Added behavior-first Python pipeline tests and Pester wrapper-resolution tests.
- Corrected the root/plugin descriptions so they no longer claim the runtime is absent. No `setup.ps1` was added; Task 6 owns setup.

## Runtime contract

`prepare` creates a marked workspace with direct `01.input`, `02.process`, and `03.output` children. `render` accepts only a direct PDF in `01.input`, writes `page-####.png` directly to `02.process`, and skips existing pages on retry. `preprocess` writes local Pillow output under `02.process/preprocessed`.

Codex OCR remains local and checkpointed: it writes `02.process/ocr/page-####.md`. `merge` requires every rendered page checkpoint in numeric order and creates `03.output/<stem>.md`; `export` creates the matching DOCX. Neither action calls an OCR API or installs dependencies.

Every action rejects missing workspace marker/children, path escape, and symlink/reparse targets. `cleanup` needs `--confirm`, checks for a matching `.md`/`.docx` output pair, recursively rejects reparse entries, and removes only `01.input` and `02.process`.

The PowerShell wrapper selects a PATH `officecli` only when `--version` is at least `1.0.135`; otherwise it verifies the bundled executable against SHA-256 `937DB176B585E874AA5BFF48D536BCE78037665CD862B5DEEFE56E79977E6588`. It invokes the resolved command with an argument array, preserves native stdout/stderr, and exits with the native exit code.

## TDD evidence

### RED

Before runtime code existed:

```text
python -m unittest tests/test_pdf_pipeline.py
FAILED (failures=6)
can't open file ...\skills\pdf-scan-to-docx\scripts\pipeline.py

Invoke-Pester -Script .\tests\Invoke-OfficeCli.Tests.ps1
Passed: 0 Failed: 2
invoke-officecli.ps1 is not recognized
```

After the first minimal implementation, two pipeline tests exposed real contract gaps:

```text
cleanup ... required output is missing ...\02.process\source.json
merge ... required output is missing ...\ocr\page-0002.md
```

Cleanup was changed to require the actual completed output pair rather than a transient manifest; merge now reports missing OCR checkpoints explicitly.

The first wrapper GREEN run exposed a real stderr defect:

```text
RemoteException: ERR:x with spaces
at invoke-officecli.ps1: line 36
```

`$ErrorActionPreference` is now `Continue` only for the final native OfficeCLI invocation, preserving stderr and the raw exit status.

### GREEN

```text
python -m unittest tests/test_pdf_pipeline.py
Ran 6 tests in 7.713s
OK

Invoke-Pester -Script .\tests\Invoke-OfficeCli.Tests.ps1 -PassThru
Passed: 2 Failed: 0 Skipped: 0

python ...\skill-creator\scripts\quick_validate.py plugins\office-toolkit-windows\skills\pdf-scan-to-docx
Skill is valid!
```

The Python tests exercise render/preprocess/resume, sorted merge, DOCX export, missing checkpoints, input path escape, missing marker/wrong workspace, confirmation-gated cleanup, output-pair gating, and a real NTFS symlink-or-junction reparse rejection. The Pester tests exercise supported PATH preference with raw stdout/stderr/nonzero exit propagation and old-PATH fallback to the hash-verified bundled executable.

## Policy and diff checks

```text
runtime_network_or_pip_matches=0
public_vendor_skill_link_matches=0
wrapper_shell_concat_matches=0
vendor_diff_files=0
lock_exact=True
git diff --check
diff_check=PASS
```

Vendor source trees were not edited. Raw PDF assets remain workspace input only; the public skill links only to its sanitized project-owned reference.

## Concern

No concern within Task 5 scope. Task 6 still owns repeatable environment setup, full plugin/package validation, and end-to-end release smoke testing.
