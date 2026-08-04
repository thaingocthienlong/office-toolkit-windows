---
name: office-docx
description: "Use when creating, editing, reviewing, or validating Word/DOCX documents, fillable forms, academic papers, Vietnamese administrative documents (NĐ30), or branded Word files. Dùng khi tạo, sửa, kiểm tra tài liệu Word/DOCX, biểu mẫu, bài báo học thuật, văn bản hành chính theo NĐ30, hoặc tài liệu Word theo brand kit."
---

# Office DOCX

Use OfficeCLI only through shared wrapper `../../scripts/invoke-officecli.ps1`, resolved from `plugins/office-toolkit-windows`. Do not install OfficeCLI or run vendored Python/Node generators.

1. Open or create target, inspect existing outline first, then make structural edits before content and formatting.
2. Ask `officecli help docx <element>` through wrapper before an uncertain property. Save before non-OfficeCLI reads.
3. Validate with wrapper; inspect text and HTML preview; fix placeholder leaks, layout issues, and invalid structure before delivery.

## Load only needed reference

| Need | Read |
|---|---|
| Normal Word/DOCX | [OfficeCLI DOCX](../../assets/vendor/xu-ly-van-phong-cli/references/skills/officecli-docx/SKILL.md) |
| Fillable form, contract, merge field | [Word forms](../../assets/vendor/xu-ly-van-phong-cli/references/skills/officecli-word-form/SKILL.md) |
| Thesis, citations, bibliography, equations | [Academic papers](../../assets/vendor/xu-ly-van-phong-cli/references/skills/officecli-academic-paper/SKILL.md) |
| Vietnamese công văn, quyết định, tờ trình | [NĐ30](../../assets/vendor/xu-ly-van-phong/standards/nd30.md) and relevant [administrative template](../../assets/vendor/xu-ly-van-phong/templates/docx-hanh-chinh-cong-van.md) |
| Corporate branding | [brand kits](../../assets/vendor/xu-ly-van-phong/standards/brand_kits/README.md) |

NĐ30 is black/white, Times New Roman, and must not mix with a brand kit. For branded documents, use provided brand assets or choose a preset with user approval; never use `brand_kits/example` for a real deliverable.

## Delivery gate

Run wrapper-backed `validate`, `view text`, and `view html`. Confirm no unresolved placeholders, overflow/truncation, or escaped `\\n`/`\\t`; confirm fields and form controls structurally where applicable. Report viewer-dependent field recalculation honestly.
