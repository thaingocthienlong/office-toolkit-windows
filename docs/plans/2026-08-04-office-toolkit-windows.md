# Office Toolkit Windows v0.1 implementation plan

## Global constraints

- Windows 10/11 x64 only.
- Exactly four public skills: `office-docx`, `office-pptx`, `office-xlsx`, and `pdf-scan-to-docx`.
- OfficeCLI is the active Office backend. Legacy Python/Node Office code is reference-only.
- Python is active only for PDF processing.
- No MCP server, app, hook, hidden network installer, or runtime `pip install`.
- Private-use distribution only until provenance and redistribution rights are verified.
- Preserve collected Office/PDF sources inside plugin assets; keep `viet-chuyen-nghiep-v3.1` in the repository but outside the plugin package.

## Task 1: Repository and plugin foundation

- Add the local marketplace and skills-only plugin manifest for `office-toolkit-windows` version `0.1.0`.
- Move the three Office/PDF source folders into the plugin vendor asset tree while preserving Git history.
- Add provenance, third-party notice, requirements lock, root installation documentation, and package boundaries.
- Keep the editorial skill folder outside the plugin.

## Task 2: `office-docx`

- Create the public Word skill with bilingual trigger-only metadata and OpenAI UI metadata.
- Cover Word documents, forms, academic papers, Vietnamese administrative documents, NĐ30, and brand kits.
- Route active work through the shared OfficeCLI wrapper and progressively load concise references.
- Pressure-test English, Vietnamese, ambiguous, and negative prompts before accepting the skill.

## Task 3: `office-pptx`

- Create the public presentation skill with bilingual trigger-only metadata and OpenAI UI metadata.
- Cover standard presentations, pitch decks, morph, morph 3D, and the bundled style collection.
- Route active work through the shared OfficeCLI wrapper and progressively load concise references.
- Pressure-test English, Vietnamese, ambiguous, and negative prompts before accepting the skill.

## Task 4: `office-xlsx`

- Create the public spreadsheet skill with bilingual trigger-only metadata and OpenAI UI metadata.
- Cover standard workbooks, financial models, and data dashboards.
- Route active work through the shared OfficeCLI wrapper and progressively load concise references.
- Pressure-test English, Vietnamese, ambiguous, and negative prompts before accepting the skill.

## Task 5: `pdf-scan-to-docx` and runtime safety

- Create the PDF skill and active Python scripts for PDF-to-images, preprocessing, page checkpoints, Markdown merge, DOCX export, resume, and guarded cleanup.
- Use `01.input`, `02.process`, and `03.output` under one resolved workspace root.
- Cleanup is opt-in and may delete only validated `01.input` and `02.process` after `.md` and `.docx` outputs exist.
- Add the shared OfficeCLI wrapper with PATH version preference and hash-verified bundled fallback.
- Add behavior-first tests, including path escape and wrong-workspace rejection.

## Task 6: Setup, smoke verification, packaging, and private release

- Add one idempotent root `setup.ps1` that verifies platform/tooling, creates the local venv, installs the locked requirements, registers the local marketplace, and installs the plugin.
- Add one smoke test that covers repeat setup checks, OfficeCLI resolution, synthetic Vietnamese scanned PDF processing, resume, output validation, and cleanup safety.
- Validate every skill and the plugin with the official validators.
- Package a private-use ZIP and SHA-256, install it locally, verify `codex.cmd plugin list`, then publish the private GitHub repository and `v0.1.0` release.
