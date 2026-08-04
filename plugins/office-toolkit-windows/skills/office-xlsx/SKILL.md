---
name: office-xlsx
description: "Use when creating, editing, reviewing, importing, or validating Excel/XLSX workbooks, formulas, financial models, trackers, charts, or data dashboards; Dùng khi tạo, sửa, nhập dữ liệu, kiểm tra workbook Excel/XLSX, công thức, mô hình tài chính, bảng theo dõi, biểu đồ, hoặc dashboard dữ liệu."
---

# Office XLSX

Route every workbook task through the shared Windows interface `../../scripts/invoke-officecli.ps1`. Do not call OfficeCLI directly, install anything from the network, use MCP/apps/hooks, or run legacy Python/Node Office runtimes.

## Route, then load only what applies

| Request | Read |
|---|---|
| Normal workbook, tracker, import, formulas, or workbook review | [Normal workbooks](references/normal-workbook.md) |
| Budget, forecast, valuation, or three-statement model | [Financial models](references/financial-model.md) |
| KPI, reporting, chart, or interactive data dashboard | [Data dashboards](references/dashboard.md) |

Read selected references directly from this skill. Do not follow links from them into vendor `SKILL.md` files; vendor assets are archival sources, not public runtime instructions.

## Operating contract

1. Inspect the existing workbook outline, sheets, formulas, tables, charts, styles, and dimensions before editing. Preserve an existing template's conventions unless the request changes them.
2. Ask wrapper-backed help before guessing an element, property, enum, formula-related feature, chart type, or validation rule. Make structural edits incrementally and inspect the result after each structural change.
3. Keep source inputs, assumptions, formulas, and presentation layers distinguishable. Use formulas for derived values; keep assumptions in cells rather than burying constants inside formulas.
4. Format every readable column explicitly, freeze useful headers, use meaningful number formats, and set print layout for wide tables or sheets with charts.
5. Save through the wrapper before any outside reader or renderer reads the file.

## Delivery gate

Through the shared wrapper, run issue inspection, annotated/text inspection, structural validation, and HTML preview. Confirm:

- no formula errors (`#REF!`, `#DIV/0!`, `#VALUE!`, `#NAME?`, or `#N/A`);
- sampled formulas and cached values are plausible, including cross-sheet references;
- no `###`, clipped titles, empty chart anchors, or placeholder tokens;
- widths, freezes, number formats, chart sources, and print layout fit the workbook;
- financial models show input/formula/link colors and source notes where applicable.

Do not call a workbook complete from a validation pass alone; visual preview is part of acceptance. Report viewer-dependent rendering limits honestly.

## Common mistakes

- Hardcoding a calculated total instead of using a formula.
- Hiding assumptions inside formulas or leaving undocumented hardcoded model inputs.
- Using a single-column chart range without categories.
- Writing a cross-sheet `!` reference through an unquoted shell argument; use the wrapper's batch input and verify the stored formula.
- Applying fit-to-one-page to a tall data sheet and making it unreadable.
