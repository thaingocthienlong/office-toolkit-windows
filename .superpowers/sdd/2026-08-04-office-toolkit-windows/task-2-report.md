# Task 2 report: office-docx

## Scope

- Base verified: `573554417e6fce7f696f247c5a03792ee234580a`.
- Added `plugins/office-toolkit-windows/skills/office-docx/SKILL.md` and `agents/openai.yaml`.
- Removed obsolete `plugins/office-toolkit-windows/skills/.gitkeep`.
- No runtime, setup, OfficeCLI binary, vendored source, Python, or Node code added or activated.

## RED

Source: `task-2-red.md`.

Prompt: `Hãy tạo một công văn tiếng Việt đúng Nghị định 30, áp dụng bộ nhận diện thương hiệu và xuất DOCX đã kiểm tra.`

Observed baseline selected generic `documents`; it did not route to an OfficeCLI DOCX workflow. GREEN target is explicit `office-docx` selection, progressive NĐ30/brand reference loading, shared wrapper use, and validation.

## GREEN

- Trigger-only bilingual description covers Word/DOCX, forms, academic papers, Vietnamese administrative documents/NĐ30, and branded documents.
- Body routes active OfficeCLI calls only through stable Task 5 interface `../../scripts/invoke-officecli.ps1` (from plugin root); it forbids installer and legacy Python/Node execution.
- Direct, one-level links load only normal DOCX, form, academic, NĐ30/template, or brand-kit source as needed.
- NĐ30 and brand-kit tracks are exclusive: NĐ30 is black/white Times New Roman; real branded output needs supplied assets or approved preset, never `brand_kits/example`.
- Delivery gate requires wrapper-backed `validate`, `view text`, and `view html` plus structural field/form checks.

## Prompt-route checks

| Prompt class | Expected route | Evidence |
|---|---|---|
| English: "Create a fillable DOCX contract" | `office-docx` then Word forms | Description has `fillable forms`; direct Word-form link present. |
| Vietnamese: "Soạn công văn theo NĐ30" | `office-docx` then NĐ30/template | Description has Vietnamese NĐ30 trigger; NĐ30/template links present. |
| Ambiguous: "Review this Word report" | `office-docx` then normal DOCX | Description covers reviewing Word/DOCX; normal DOCX link present. |
| Negative: "Install OfficeCLI and run template_docx.js" | Do not activate this skill runtime path | Body permits wrapper only and forbids install/vendored Python/Node generators. |

These are deterministic routing/content audits, not live document generation. Shared wrapper lands in Task 5, so its runtime invocation cannot yet be smoke-tested.

## Self-review

- Kept two skill files only; no copied references, scripts, setup, or abstraction.
- UI metadata is quoted and its default prompt names `$office-docx`.
- All source links resolve from `skills/office-docx`; no reference chains created inside this skill.
- Added no task-specific document template as generic OfficeCLI/NĐ30 sources already cover it.

## Checks

```text
python C:\Users\Vien Phuong Nam\.codex\skills\.system\skill-creator\scripts\quick_validate.py plugins\office-toolkit-windows\skills\office-docx
Skill is valid!

Focused metadata/path/runtime-boundary check
PASS metadata, paths, active-runtime boundary
```

## Concern

Task 5 must implement the documented shared wrapper contract before live OfficeCLI DOCX smoke execution is possible.

## Fix round 1

Finding: combined NĐ30 + brand requests had a prohibition but no user-facing conflict gate.

Fix: `SKILL.md` now identifies NĐ30 and brand styling as mutually exclusive tracks, explains the conflict, asks the user to choose, and blocks generation until selection.

Command/output:

```text
python C:\Users\Vien Phuong Nam\.codex\skills\.system\skill-creator\scripts\quick_validate.py plugins\office-toolkit-windows\skills\office-docx
Skill is valid!

Focused combined-route check
PASS: conflict text, choose-track instruction, and no-generation gate present
```
