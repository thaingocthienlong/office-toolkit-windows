---
name: office-pptx
description: "Use when creating, editing, reviewing, validating, or extracting PowerPoint/PPTX presentations, pitch decks, Morph or Morph 3D slides, or bundled OfficeCLI styles; Dùng khi tạo, sửa, kiểm tra, xác thực, trích xuất PowerPoint/PPTX, pitch deck, slide Morph/Morph 3D, hoặc style OfficeCLI bundled."
---

# Office PPTX

Route every PPTX task through shared Windows interface `../../scripts/invoke-officecli.ps1`.
Do not call `officecli` directly. Do not install tools from network. Do not use legacy Python or Node Office runtimes/generators.

## Route, then load only what applies

| Request | Read |
|---|---|
| Normal presentation, slide editing, inspection, or validation | [OfficeCLI PPTX](../../assets/vendor/xu-ly-van-phong-cli/references/skills/officecli-pptx/SKILL.md) |
| Fundraising, investor, seed, Series A/B/C, SAFE, or VC deck | [Pitch deck](../../assets/vendor/xu-ly-van-phong-cli/references/skills/officecli-pitch-deck/SKILL.md) |
| Morph transition or cross-slide motion | [Morph PPT](../../assets/vendor/xu-ly-van-phong-cli/references/skills/morph-ppt/SKILL.md) |
| Morph plus a `.glb` model or 3D camera/layout | [Morph 3D](../../assets/vendor/xu-ly-van-phong-cli/references/skills/morph-ppt-3d/SKILL.md) |
| Bundled visual style selection | [Style library index](../../assets/vendor/xu-ly-van-phong-cli/references/skills/morph-ppt/reference/styles/INDEX.md), then selected style's `style.md` |

Read base PPTX reference first when scene reference says inherited. Read only selected variant/style reference after routing; keep reference loading one level deep from this file.

## Operating contract

1. Inspect existing deck structure, theme, masters, layouts, notes, and assets before editing. Preserve existing template conventions unless request changes them.
2. Ask wrapper-backed OfficeCLI help before guessing an element, property, enum, transition, animation, chart, or 3D option. Execute incrementally and inspect structural readback after structural edits.
3. Build one idea per slide with explicit text sizes, readable contrast, coherent palette, and informative visual. Keep speaker notes on content slides. Never invent metrics, placeholder copy, or brand assets.
4. For Morph, bind persistent actors with identical names across adjacent slides; use off-canvas ghosting for exits. Treat non-PowerPoint renderers as fade-only for Morph. For Morph 3D, require `.glb`; never silently substitute another model format.
5. For styles, choose from bundled index and selected preset. Never use library `example/` kit for real deliverable; user-provided brand assets take precedence.

## Delivery gate

Through shared wrapper, run structural validation, text inspection, and visual/annotated preview checks available for target. Confirm slide order, no placeholder leaks, no overflow/clipping, readable contrast, intact hyperlinks, notes, and requested transitions/assets. Report renderer-dependent Morph or 3D limits honestly; generated file alone is not completion.
